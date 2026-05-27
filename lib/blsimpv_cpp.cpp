// Written by Jean-François Bégin on December 9, 2014.
//
// Price CDS quickly. 
//
#include <math.h>
#include "mex.h"
#define PI 3.14159265358979323846264338327
#define TOLERANCE 0.0000001

// THIS FUNCTION min RETURNS THE MINIMUM BETWEEN a AND b
//
// INPUT:
//      a:          A DOUBLE
//      b:          ANOTHER DOUBLE
//
// OUTPUT:
//      THE MINIMUM BETWEEN a AND b
//
double min(double a, double b)
{
    if (a < b)
        return a;
    else
        return b;
}

// THIS FUNCTION max RETURNS THE MINIMUM BETWEEN a AND b
//
// INPUT:
//      a:          A DOUBLE
//      b:          ANOTHER DOUBLE
//
// OUTPUT:
//      THE MAXIMUM BETWEEN a AND b
//
double max(double a, double b)
{
    if (a < b)
        return b;
    else
        return a;
}

// THIS FUNCTION normpdf RETURNS THE PDF OF A STANDARDIZED GAUSSIAN 
// DISTRIBUTION. 
//
// INPUT:
//      X:          WHERE TO EVALUATE THE PDF.
//
// OUTPUT:
//      THE PDF.
//
double normpdf(double X)
{
    return 1/sqrt(2*PI)*exp(-X*X/2);
}

// THIS FUNCTION normcdf RETURNS THE CDF OF A STANDARDIZED GAUSSIAN 
// DISTRIBUTION. 
//
// INPUT:
//      X:          WHERE TO EVALUATE THE CDF.
//
// OUTPUT:
//      THE CDF.
//
double normcdf(double X)
{
    double s,t,b,q,i;
    
    if (X < -8)
        return 0;
    else if (X > 8)
        return 1;
    else
    {
        s = X;
        t = 0;
        b = X;
        q = X*X;
        i = 1;
        while(s!=t)
        {
            s = (t=s)+(b*=q/(i+=2));
        }
        return 0.5+s*exp(-.5*q-.91893853320467274178);
    }
}

// THIS FUNCTION bsmprice RETURNS THE PRICE OF A EUROPEAN OPTION GIVEN BY
// THE BLACK-SCHOLES. 
//
// INPUT:
//      S:          THE STOCK PRICE POST DIVIDEND, S exp(-qT)
//      K:          THE ACTUALIZED STRIKE PRICE, K exp(-rT)
//      SIGMA:      ANNUALIZED VARIANCE
//      T:          MATURITY
//      ISCALL:     1 IF CALL, 0 IF PUT
//
// OUTPUT:
//      THE INVERSE OF THE CDF.
//
double bsmprice(double S, double K, double SIGMA, double T, double ISCALL)
{
    double d1;
    d1 = (log(S/K) + (SIGMA*SIGMA/2)*T)/(SIGMA*sqrt(T));
    
    if ((int)(ISCALL + TOLERANCE) == 1)
        return S*normcdf(d1) - K*normcdf(d1-SIGMA*sqrt(T));
    else
        return K*normcdf(-d1+SIGMA*sqrt(T)) - S*normcdf(-d1);
}

/* --------------------------------------------------------------------- */
// Mex function. It is the gateway function.
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{       
    double *Price, *Strike, *Rate, *Time, *Value, *Yield, *Class, *ImplVol, *InitGuess;
    int Nb, i, j;
    double Limit, ImpVol_tmp, Value_tmp;
    int exitwhile;
    double min_b, max_b;
    
    if(nrhs!=9)
    {
        mexErrMsgIdAndTxt("MyToolbox:blsimpv_cpp:nrhs", "9 inputs required.");
    }
    
    Nb                          = mxGetM(prhs[0]);
    Price                       = mxGetPr(prhs[0]);
    Strike                      = mxGetPr(prhs[1]);
    Rate                        = mxGetPr(prhs[2]);
    Time                        = mxGetPr(prhs[3]);
    Value                       = mxGetPr(prhs[4]);
    Limit                       = mxGetScalar(prhs[5]);
    Yield                       = mxGetPr(prhs[6]);
    Class                       = mxGetPr(prhs[7]);
    InitGuess                   = mxGetPr(prhs[8]);
    
    plhs[0]                     = mxCreateDoubleMatrix(Nb, 1, mxREAL);
    ImplVol                     = mxGetPr(plhs[0]);

    for (i = 0; i < Nb; i++)
    {
        if (Value[i] < 0)
        {
            ImplVol[i]          = 0;
        }
        else
        {
            j                   = 0;
            Value_tmp           = -1;
            ImpVol_tmp          = InitGuess[i];
            exitwhile           = 0;
            max_b               = Limit;
            min_b               = 0;

            while ( fabs(Value[i] - Value_tmp) > TOLERANCE && exitwhile == 0 )
            {
                j               = j + 1;
                Value_tmp       = bsmprice(Price[i]*exp(-Time[i]*Yield[i]), Strike[i]*exp(-Time[i]*Rate[i]), ImpVol_tmp, Time[i], Class[i]);
                if (Value_tmp - Value[i] > 0)
                {
                    max_b       = ImpVol_tmp;
                    ImpVol_tmp  = min_b + (max_b-min_b)/2;
                }
                else
                {
                    min_b       = ImpVol_tmp;
                    ImpVol_tmp  = min_b + (max_b-min_b)/2;
                }
                
                if (j > 500)
                {
                    exitwhile   = 1;
                    ImpVol_tmp  = Limit;
                }
            }
            
            if ( ImpVol_tmp > Limit )
                ImplVol[i]      = Limit;
            else
                ImplVol[i]      = ImpVol_tmp;
        }
    }
}
