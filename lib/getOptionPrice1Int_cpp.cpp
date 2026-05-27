// Written by Jean-François Bégin on November 18, 2014.
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

void getPrices(double prices[], double ur[], double ui[], int nb_u, int Tmax,
               double Ar[], double Ai[], double Br[], double Bi[], double Cr[], double Ci[], double Dr[], double Di[], double Er[], double Ei[],
               double x0[], double mu0[], double v0[], double lambda0[], double K[], double T[], int nb_prices)
{
    int i, j, j0;
    double k;
    double integral;
    double call;
    double c1, x1, c2, x2;

    for (i = 0; i < nb_prices ; i++)
    {
      k = log(K[i]);
      integral = 0;
        
      j0 = (int)((T[i]-1)*nb_u);
      if (T[i] < 1) {
        cout << "T[" << i << "] = " << T[i] << endl;
        mexErrMsgIdAndTxt("getOptionPrice1Int_cpp:dtm", "DTM must be at least 1");
      }
      if (j0 + nb_u > (nb_u*Tmax)) {
        mexErrMsgIdAndTxt("getOptionPrice1Int_cpp:internal", "Internal error");
      }
      
      c1 = cos(Ai[j0]  +  Bi[j0]*x0[i] +  Ci[j0]*mu0[i] +  Di[j0]*v0[i]  +  Ei[j0]*lambda0[i]  +  k*(  - ui[0]));
      x1 = exp(Ar[j0]  +  Br[j0]*x0[i] +  Cr[j0]*mu0[i] +  Dr[j0]*v0[i]  +  Er[j0]*lambda0[i]  +  k*(1 - ur[0])) * c1;

      for (j = 1; j < nb_u; j++)
      {
        c2 = cos(Ai[j0+j]  +  Bi[j0+j]*x0[i]  +  Ci[j0+j]*mu0[i] +  Di[j0+j]*v0[i] +  Ei[j0+j]*lambda0[i]  +  k*(  - ui[j]));
        x2 = exp(Ar[j0+j]  +  Br[j0+j]*x0[i]  +  Cr[j0+j]*mu0[i] +  Dr[j0+j]*v0[i] +  Er[j0+j]*lambda0[i]  +  k*(1 - ur[j])) * c2;

        integral += (x2 + x1)*(ui[j] - ui[j-1])/2;
        x1 = x2;
      }

      prices[i] = integral/(2*PI);
    }
}

void assertSameSize(const mxArray* array1, const mxArray* array2, const string msg)
{
  int n1 = mxGetN(array1);
  int m1 = mxGetM(array1);

  int n2 = mxGetN(array2);
  int m2 = mxGetM(array2);

  string MSG = "Size of arrays is inconsistent: " + msg;
  if (n1!=n2 || m1!=m2)
    mexErrMsgIdAndTxt("getOptionPrice1Int_cpp", MSG.c_str());
}

void assertIsComplex(const mxArray* array)
{
  if( !mxIsComplex(array) )
    mexErrMsgIdAndTxt("getOptionPrice1Int_cpp:complex", "Loadings must be complex");
}

void getLoadings(double* &real_mat, double* &imag_mat, const mxArray* prhs)
{
  assertIsComplex(prhs);
  real_mat = mxGetPr(prhs);
  imag_mat = mxGetPi(prhs);
}

/* --------------------------------------------------------------------- */
// Mex function. It is the gateway.
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double* prices;
    double* ur;
    double* ui;
    double* Ar;
    double* Ai;
    double* Br;
    double* Bi;
    double* Cr;
    double* Ci;
    double* Dr;
    double* Di;
    double* Er;
    double* Ei;
    double* x0;
    double* mu0;
    double* v0;
    double* lambda0;
    double* K;
    double* T;
   
    int nb_u, Tmax;
    int nb_prices, nK, nD, nT;
    
    if(nrhs!=12)
    {
        mexErrMsgIdAndTxt("getOptionPrice1Int_cpp:nrhs", "12 inputs required.");
    }
    
    ur    = mxGetPr(prhs[0]);
    ui    = mxGetPi(prhs[0]);
    nb_u  = mxGetM(prhs[0]);    
    Tmax  = mxGetN(prhs[1]); // The loading matrices are nb_u x Tmax
        
    getLoadings(Ar, Ai, prhs[1]);
    getLoadings(Br, Bi, prhs[2]);
    getLoadings(Cr, Ci, prhs[3]);
    getLoadings(Dr, Di, prhs[4]);
    getLoadings(Er, Ei, prhs[5]);
        
    assertSameSize(prhs[1], prhs[2],  "1 vs 2");
    assertSameSize(prhs[1], prhs[3],  "1 vs 3");
    assertSameSize(prhs[1], prhs[4],  "1 vs 4");
    assertSameSize(prhs[1], prhs[5],  "1 vs 5");
    
    // The following are all column vectors
    x0        = mxGetPr(prhs[6]);
    mu0       = mxGetPr(prhs[7]);
    v0        = mxGetPr(prhs[8]);
    lambda0   = mxGetPr(prhs[9]);
    K         = mxGetPr(prhs[10]);    
    T         = mxGetPr(prhs[11]);

    nb_prices = mxGetM(prhs[6]);
    assertSameSize(prhs[6],  prhs[7],  "6 vs 7");
    assertSameSize(prhs[6],  prhs[8],  "6 vs 8");
    assertSameSize(prhs[6],  prhs[9],  "6 vs 9");
    assertSameSize(prhs[6],  prhs[10], "6 vs 10");
    assertSameSize(prhs[6],  prhs[11], "6 vs 11");

    plhs[0] = mxCreateDoubleMatrix(nb_prices, 1, mxREAL);
    prices  = mxGetPr(plhs[0]);

    getPrices(prices,ur,ui,nb_u,Tmax,Ar,Ai,Br,Bi,Cr,Ci,Dr,Di,Er,Ei,x0,mu0,v0,lambda0,K,T,nb_prices);
}

