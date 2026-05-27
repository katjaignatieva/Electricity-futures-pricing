// Written by Jean-François Bégin on May 29, 2015.
//
// Black-Scholes option price.
//
#include <math.h>
#include "mex.h"
#define PI 3.14159265358979323846264338327
#define EPSILON 0.001

static const double a[] =
    {
        -3.969683028665376e+01,
         2.209460984245205e+02,
        -2.759285104469687e+02,
         1.383577518672690e+02,
        -3.066479806614716e+01,
         2.506628277459239e+00
    };
    
static const double b[] =
    {
        -5.447609879822406e+01,
         1.615858368580409e+02,
        -1.556989798598866e+02,
         6.680131188771972e+01,
        -1.328068155288572e+01
    };

static const double c[] =
    {
        -7.784894002430293e-03,
        -3.223964580411365e-01,
        -2.400758277161838e+00,
        -2.549732539343734e+00,
         4.374664141464968e+00,
         2.938163982698783e+00
    };

static const double d[] =
    {
        7.784695709041462e-03,
        3.224671290700398e-01,
        2.445134137142996e+00,
        3.754408661907416e+00
    };

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
    int count = 0;
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


// THIS FUNCTION blsprice RETURNS THE PRICE OF A EUROPEAN OPTION GIVEN BY
// THE BLACK-SCHOLES. 
//
// INPUT:
//      Price:      THE STOCK PRICE
//      Strike:     THE STRIKE PRICE
//      Rate:       RISK-FREE INTEREST RATE
//      Time:       TIME TO MATURITY
//      Volatility: ANNUALIZED VARIANCE
//      Yield:      DIVIDEND YIELD
//      Class:      1 IF CALL, 0 IF PUT
//
// OUTPUT:
//      THE BLACK-SCHOLES OPTION PRICE.
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{       
    double *Price, *Strike, *Rate, *Time, *Volatility, *Yield, *Class, *Value;
    int Nb, Nb_tmp, i, j;
    double d1;
    
    if(nrhs!=7)
    {
        mexErrMsgIdAndTxt("MyToolbox:blsimpv_cpp:nrhs", "7 inputs required.");
    }
    
    Nb                          = mxGetM(prhs[0]);
    Nb_tmp                      = mxGetN(prhs[0]);
    if (Nb_tmp > Nb)
        Nb = Nb_tmp;
    
    Price                       = mxGetPr(prhs[0]);
    Strike                      = mxGetPr(prhs[1]);
    Rate                        = mxGetPr(prhs[2]);
    Time                        = mxGetPr(prhs[3]);
    Volatility                  = mxGetPr(prhs[4]);
    Yield                       = mxGetPr(prhs[5]);
    Class                       = mxGetPr(prhs[6]);
    
    plhs[0]                     = mxCreateDoubleMatrix(Nb, 1, mxREAL);
    Value                       = mxGetPr(plhs[0]);

    for (i = 0; i < Nb; i++)
    {
        d1 = (log(Price[i]/Strike[i]) + (Rate[i] - Yield[i] + Volatility[i]*Volatility[i]/2)*Time[i])/(Volatility[i]*sqrt(Time[i]));
    
        if (Class[i] == 1)
            Value[i] = Price[i]*exp(-Yield[i]*Time[i])*normcdf(d1) - Strike[i]*exp(-Rate[i]*Time[i])*normcdf(d1-Volatility[i]*sqrt(Time[i]));
        else
            Value[i] = Strike[i]*exp(-Rate[i]*Time[i])*normcdf(-d1+Volatility[i]*sqrt(Time[i]))-Price[i]*exp(-Yield[i]*Time[i])*normcdf(-d1);
    }
    
}
    
    
    
    
