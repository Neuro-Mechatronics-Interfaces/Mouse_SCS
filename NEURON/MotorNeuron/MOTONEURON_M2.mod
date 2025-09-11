:SOMA

: Max Murphy
:
:
: This model has been adapted and is described in detail in:
:
: McIntyre CC and Grill WM. Extracellular Stimulation of Central Neurons:
: Influence of Stimulus Waveform and Frequency on Neuronal Output
: Journal of Neurophysiology 88:1592-1604, 2002.
:
: Notable change is the addition of RANGE parameter `m2_modulation` and its inclusion in the calculation of `ikrect` as indicated by comments.

TITLE Motor Axon Soma with M2 Receptor Modulation

INDEPENDENT {t FROM 0 TO 1 WITH 1 (ms)}

NEURON {
    SUFFIX motoneuron_m2
    NONSPECIFIC_CURRENT ina
    NONSPECIFIC_CURRENT ikrect
    NONSPECIFIC_CURRENT ikca
    NONSPECIFIC_CURRENT il
    NONSPECIFIC_CURRENT icaN
    NONSPECIFIC_CURRENT icaL
    RANGE  gnabar, gl, ena, ek, el, gkrect, gcaN, gcaL, gcak
    RANGE p_inf, m_inf, h_inf, n_inf, mc_inf, hc_inf
    RANGE tau_p, tau_m, tau_h, tau_n, tau_mc, tau_hc, tau_ca
    RANGE m2_modulation, tau_m_gain, tau_h_gain, tau_n_gain
    RANGE gcaL, gcaL_pic, pic_ton, pic_tau, kdrop
    RANGE pic_gate
}

UNITS {
    (mA) = (milliamp)
    (mV) = (millivolt)
    (molar) = (1/liter)     
    (mM) = (millimolar)    
}

PARAMETER {
    :SOMA PARAMETERS
    gnabar  = 0.05  (mho/cm2)
    gl      = 0.002 (mho/cm2)
	gkrect = 0.3 (mho/cm2)
    gcaN    = 0.05  (mho/cm2)
    gcaL    = 0.0001 (mho/cm2)
    gcak    = 0.3   (mho/cm2)
    ca0     = 2     (mM)
    ena     = 50.0  (mV)
    ek      = -80.0 (mV)
    el      = -70.0 (mV)
    amA = 0.4
    amB = 66
    amC = 5
    bmA = 0.4
    bmB = 32
    bmC = 5
    cai_min = 1e-6 (mM) : minimum cai to avoid log(0)
    R=8.314472 : Universal gas constant (J / mol*K)
    F=96485.34 : Faraday constant (C / mol)
    m2_modulation = 1 (1)  <0,1>  : dimensionless, clipped in [0,1]
    tau_m_gain = 1 (1) <0,2> : <0,2> dimensionless
    tau_h_gain = 1 (1) <0,2> : <0,2> dimensionless
    tau_n_gain = 1 (1) <0,2> : <0,2> dimensionless
    tau_ca = 20 (ms) <10, 200> : calcium removal time constant
    gcaL_pic = 0.001  (mho/cm2)   : stronger L-type once PIC is "on"
    pic_ton  = 10000  (ms)        : time (ms) when PIC starts turning on; default never turns it on.
    pic_tau  = 5      (ms)        : smoothness of the switch
    kdrop    = 0      (1) <0,1>   : optional fractional drop of Kdr after PIC onset
}

STATE {
    p 
    m 
    h 
    n 
    cai (mM) 
    mc 
    hc
}

ASSIGNED {
    ina  (mA/cm2)
    il      (mA/cm2)
    ikrect    (mA/cm2)
    icaN  (mA/cm2)
    icaL  (mA/cm2)
    ikca  (mA/cm2)
    Eca  (mV)
    m_inf
    mc_inf
    h_inf
    hc_inf
    n_inf
    p_inf
    tau_m
    tau_h
    tau_p
    tau_n
    tau_mc
    tau_hc
    pic_gate (1)
}

BREAKPOINT {
    SOLVE states METHOD cnexp
    pic_gate = 1 / (1 + Exp(-(t - pic_ton)/pic_tau))
    ina = gnabar * m*m*m*h*(v - ena)
    : ikrect = gkrect * (1 / (Exp(m2_modulation))) *n*n*n*n* (v - ek)  : m2_modulation in [0..1]
    ikrect = gkrect * (1 - kdrop*pic_gate) * (1 / (Exp(m2_modulation))) * n*n*n*n* (v - ek) : m2_modulation + kdrop/gate

    il = gl * (v - el)
    : Guard Eca against tiny cai to avoid log(ca0/0) -> inf
    if (cai <= 1e-6) {
        Eca = ((1000*R*309.15)/(2*F)) * log(ca0/cai_min)
    } else {
        Eca = ((1000*R*309.15)/(2*F)) * log(ca0/cai)
    }
    icaN = gcaN * mc*mc * hc * (v - Eca)
    : icaL = gcaL * p * (v - Eca) : original
    icaL = (gcaL + (gcaL_pic - gcaL)*pic_gate) * p * (v - Eca)
    ikca = gcak * (cai*cai) / (cai*cai + 0.014*0.014) * (v - ek)
}

DERIVATIVE states {
    : exact Hodgkin-Huxley equations
    evaluate_fct(v)
    m' = (m_inf - m) / tau_m
    h' = (h_inf - h) / tau_h
    p' = (p_inf - p) / tau_p
    n' = (n_inf - n) / tau_n
    mc' = (mc_inf - mc) / tau_mc
    hc' = (hc_inf - hc) / tau_hc
    cai' = 0.01 * (-(icaN + icaL) - cai / (0.01 * tau_ca))
}

UNITSOFF

INITIAL {
    evaluate_fct(v)
    m = m_inf
    h = h_inf
    p = p_inf
    n = n_inf
    mc = mc_inf
    hc = hc_inf
    cai = 0.0001
}

PROCEDURE evaluate_fct(v (mV)) { LOCAL a, b, v2
    :FAST SODIUM
    :m
    a = alpham(v)
    b = betam(v)
    : tau_m = 1 / (a + b) : original
	tau_m = (1 / (a + b))*tau_m_gain : updated
    m_inf = a / (a + b)
    :h
    : tau_h = 30 / (Exp((v + 60) / 15) + Exp(-(v + 60) / 16)) : original
	tau_h = (30 / (Exp((v+60)/15) + Exp(-(v+60)/16))) * tau_h_gain : updated
    h_inf = 1 / (1 + Exp((v + 65) / 7))

    :DELAYED RECTIFIER POTASSIUM
    : tau_n = 5 / (Exp((v + 50) / 40) + Exp(-(v + 50) / 50)) : original
	tau_n = (5 / (Exp((v + 50) / 40) + Exp(-(v + 50) / 50)))*tau_n_gain : updated
    n_inf = 1 / (1 + Exp(-(v + 38) / 15))

    :CALCIUM DYNAMICS
    :N-type
    tau_mc = 15
    mc_inf = 1 / (1 + Exp(-(v + 32) / 5))
    tau_hc = 50
    hc_inf = 1 / (1 + Exp((v + 50) / 5))

    :L-type
    tau_p = 400 : original
    p_inf = 1 / (1 + Exp(-(v + 55.8) / 3.7))
}

FUNCTION alpham(x) {
    if (fabs((x + amB) / amC) < 1e-6) {
        alpham = amA * amC
    } else {
        alpham = (amA * (x + amB)) / (1 - Exp(-(x + amB) / amC))
    }
}

FUNCTION betam(x) {
    if (fabs((x + bmB) / bmC) < 1e-6) {
        betam = -bmA * bmC
    } else {
        betam = (bmA * (-(x + bmB))) / (1 - Exp((x + bmB) / bmC))
    }
}

FUNCTION Exp(x) {
    if (x < -100) {
        Exp = 0
    } else if (x > 100) {
        Exp = exp(100)   : large but finite; prevents overflow
    } else {
        Exp = exp(x)
    }
}


UNITSON
