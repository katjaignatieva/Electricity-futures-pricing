// Written by Jean-François Bégin on November 5, 2019.
//
// Price European options quickly. 
//
#include <iostream>
#include <math.h>
#include "mex.h"
using namespace std;

#define PI 3.14159265358979323846264338327

// Returns the minimum between a and b
double min(double a, double b)
{
    if (a < b)
        return a;
    else
        return b;
}

// Returns the maximum between a and b
double max(double a, double b)
{
    if (a < b)
        return b;
    else
        return a;
}

/* --------------------------------------------------------------------- */
// Main function.

// Using Gil-Pelaez' inversion method. 
// This method requires two sets of matrices A and B (both real and imaginary parts).
void getPrices(double prices[], double u[], int nb_u, int Tmax,
               double Ar[], double Ai[], double Br[], double Bi[], double Cr[], double Ci[],  double Dr[], double Di[],
               double x0[], double v0[], double lambda0[], double K[],  double T[], double flag[], int nb_prices)
{
    int i, j, j0;
    double k; // D is the discount factor
    double integral;
    double call;
    double s1, x1, s2, x2, s3, x3, s4, x4;

    for (i = 0; i < nb_prices ; i++)
    {
      integral = 0;
      
      j0 = (int)((T[i]-1)*nb_u);
      if (T[i] < 1) {
        cout << "T[" << i << "] = " << T[i] << endl;
        mexErrMsgIdAndTxt("SVCJ:getOptionPrice_cpp", "DTM must be at least 1");
      }
      if (j0 + nb_u > (nb_u*Tmax)) {
        mexErrMsgIdAndTxt("SVCJ:getOptionPrice_cpp", "Internal error");
      }
      
      s1 = sin(A1i[j0]  +  B1i[j0]*V1[i]  +  C1i[j0]*V2[i] +  k*u[0]);
      x1 = exp(A1r[j0]  +  B1r[j0]*V1[i]  +  C1r[j0]*V2[i])  * s1 / u[0];
  
      s3 = sin(A2i[j0]  +  B2i[j0]*V1[i]  +  C2i[j0]*V2[i] +  k*u[0]);
      x3 = exp(A2r[j0]  +  B2r[j0]*V1[i]  +  C2r[j0]*V2[i]) * s3 / u[0];
      
      for (j = 1; j < nb_u; j++)
      {
        s2 = sin(A1i[j0+j]  +  B1i[j0+j]*V1[i]  +  C1i[j0+j]*V2[i]+  k*u[j]);
        x2 = exp(A1r[j0+j]  +  B1r[j0+j]*V1[i]  +  C1r[j0+j]*V2[i]) * s2 / u[j];

        s4 = sin(A2i[j0+j]  +  B2i[j0+j]*V1[i] +  C2i[j0+j]*V2[i] +  k*u[j]);
        x4 = exp(A2r[j0+j]  +  B2r[j0+j]*V1[i] +  C2r[j0+j]*V2[i]) * s4 / u[j];
            
        integral1 += (x2 + x1)*(u[j] - u[j-1])/2;
        integral2 += (x3 + x4)*(u[j] - u[j-1])/2;
            
        x1 = x2;
        x3 = x4;
      }

      call = S0[i]*(0.5+integral1/PI) - D[i]*K[i]*(0.5+integral2/PI);
      prices[i] = max(0.0001,flag[i]*call + (1-flag[i])*(call + D[i]*K[i] - S0[i]));
    }
}

void assertSameSize(const mxArray* array1, const mxArray* array2, const string msg)
{
  int n1 = mxGetN(array1);
  int m1 = mxGetM(array1);

  int n2 = mxGetN(array2);
  int m2 = mxGetM(array2);

  string MSG = "Size of arrays is inconsistent: "+msg;
  if (n1!=n2 || m1!=m2)
    mexErrMsgIdAndTxt("SV:getOptionPrice_cpp", MSG.c_str());
}

void assertIsComplex(const mxArray* array)
{
  if( !mxIsComplex(array) )
    mexErrMsgIdAndTxt("SV:getOptionPrice_cpp:", "Loadings must be complex");
}

void getLoadings(double* &real_mat, double* &imag_mat, const mxArray* prhs)
{
  assertIsComplex(prhs);
  real_mat = mxGetPr(prhs);
  imag_mat = mxGetPi(prhs);
}

/* --------------------------------------------------------------------- */
// Mex function. It is the gateway.
// IMPORTANT: D must be the discount rate corresponding to the option's
//            maturity. E.g. D = exp(-r (T / 365))
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    double* prices;
    double* u;
    double* A1r;
    double* A1i;
    double* B1r;
    double* B1i;
    double* C1r;
    double* C1i;
    double* A2r;
    double* A2i;
    double* B2r;
    double* B2i;
    double* C2r;
    double* C2i;
    double* V1;
    double* V2;
    double* S0;
    double* K;
    double* D;
    double* T;
    double* flag;
   
    int nb_u, Tmax;
    int nb_prices, nK, nD, nT, nflag;
    
    if(nrhs!=14)
    {
        mexErrMsgIdAndTxt("SV:getOptionPrice_cpp:nrhs", "14 inputs required.");
    }
    
    u     = mxGetPr(prhs[0]);
    nb_u  = mxGetN(prhs[0]);    
    Tmax  = mxGetN(prhs[1]); // The loading matrices are nb_u x Tmax
        
    getLoadings(A1r,  A1i,  prhs[1]);
    getLoadings(B1r,  B1i,  prhs[2]);
    getLoadings(C1r,  C1i,  prhs[3]);
    getLoadings(A2r,  A2i,  prhs[4]);
    getLoadings(B2r,  B2i,  prhs[5]); 
    getLoadings(C2r,  C2i,  prhs[6]); 
        
    assertSameSize(prhs[1], prhs[2], "1 vs 2");
    assertSameSize(prhs[1], prhs[3], "1 vs 3");
    assertSameSize(prhs[1], prhs[4], "1 vs 4");
    assertSameSize(prhs[1], prhs[5], "1 vs 5");
    assertSameSize(prhs[1], prhs[6], "1 vs 6");

    // The following are all column vectors
    V1        = mxGetPr(prhs[7]);
    V2        = mxGetPr(prhs[8]);
    
    S0        = mxGetPr(prhs[9]);
    K         = mxGetPr(prhs[10]);    
    D         = mxGetPr(prhs[11]);
    T         = mxGetPr(prhs[12]);
    flag      = mxGetPr(prhs[13]);

    nb_prices = mxGetM(prhs[9]);
    assertSameSize(prhs[9], prhs[ 7], "9 vs 7");
    assertSameSize(prhs[9], prhs[ 8], "9 vs 8");
    assertSameSize(prhs[9], prhs[10], "9 vs 10");
    assertSameSize(prhs[9], prhs[11], "9 vs 11");
    assertSameSize(prhs[9], prhs[12], "9 vs 12");
    assertSameSize(prhs[9], prhs[13], "9 vs 13");

    plhs[0] = mxCreateDoubleMatrix(nb_prices, 1, mxREAL);
    prices  = mxGetPr(plhs[0]);

    getPrices(prices,u,nb_u,Tmax,
              A1r,A1i,B1r,B1i,C1r,C1i,
              A2r,A2i,B2r,B2i,C2r,C2i,
              V1,V2,S0,K,D,T,flag,nb_prices);
}

