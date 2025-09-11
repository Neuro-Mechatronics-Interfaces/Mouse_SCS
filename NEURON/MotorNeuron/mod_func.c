#include <stdio.h>
#include "hocdec.h"
#define IMPORT extern __declspec(dllimport)
IMPORT int nrnmpi_myid, nrn_nobanner_;

extern void _axnode_reg();
extern void _initial_reg();
extern void _motoneuron_reg();
extern void _motoneuron_5ht_reg();
extern void _motoneuron_ff_reg();
extern void _motoneuron_m2_reg();

void modl_reg(){
	//nrn_mswindll_stdio(stdin, stdout, stderr);
    if (!nrn_nobanner_) if (nrnmpi_myid < 1) {
	fprintf(stderr, "Additional mechanisms from files\n");

fprintf(stderr," axnode.mod");
fprintf(stderr," initial.mod");
fprintf(stderr," motoneuron.mod");
fprintf(stderr," motoneuron_5ht.mod");
fprintf(stderr," motoneuron_ff.mod");
fprintf(stderr," motoneuron_m2.mod");
fprintf(stderr, "\n");
    }
_axnode_reg();
_initial_reg();
_motoneuron_reg();
_motoneuron_5ht_reg();
_motoneuron_ff_reg();
_motoneuron_m2_reg();
}
