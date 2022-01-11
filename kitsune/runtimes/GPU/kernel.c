#include"kernelHeader.h"
#include<math.h>

void kitsune_kernel(double* x, double* y, double* z){
  int id = gtid(); 
	z[id] = y[id] + sqrt(x[id]); 
}

