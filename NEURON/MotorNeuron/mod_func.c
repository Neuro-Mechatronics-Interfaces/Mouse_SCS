#include <stdio.h>
#include "hocdec.h"
#define IMPORT extern __declspec(dllimport)
IMPORT int nrnmpi_myid, nrn_nobanner_;

extern void _AXNODE_reg();
extern void _INITIAL_reg();
extern void _MOTONEURON_reg();
extern void _MOTONEURON_5HT_reg();
extern void _MOTONEURON_M2_reg();

void modl_reg(){
	//nrn_mswindll_stdio(stdin, stdout, stderr);
    if (!nrn_nobanner_) if (nrnmpi_myid < 1) {
	fprintf(stderr, "Additional mechanisms from files\n");

fprintf(stderr," AXNODE.mod");
fprintf(stderr," INITIAL.mod");
fprintf(stderr," MOTONEURON.mod");
fprintf(stderr," MOTONEURON_5HT.mod");
fprintf(stderr," MOTONEURON_M2.mod");
fprintf(stderr, "\n");
    }
_AXNODE_reg();
_INITIAL_reg();
_MOTONEURON_reg();
_MOTONEURON_5HT_reg();
_MOTONEURON_M2_reg();
}
