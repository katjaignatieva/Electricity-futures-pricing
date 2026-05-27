#include "math.h"
#include "mex.h"

#define MEMALLOC(x) mxMalloc(x)
#define MEMFREE(x) mxFree(x)
#define DOUBLE_EPSILON 0.000001
#define PI 3.1415926535897932

double normcdf(double x)
{
    double a1 =  0.254829592;
    double a2 = -0.284496736;
    double a3 =  1.421413741;
    double a4 = -1.453152027;
    double a5 =  1.061405429;
    double p  =  0.3275911;

    int sign = 1;
    if (x < 0)
        sign = -1;
    x = fabs(x)/sqrt(2.0);

    double t = 1.0/(1.0 + p*x);
    double y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*exp(-x*x);

    return 0.5*(1.0 + sign*y);
}

double max(double a, double b)
{
    if (a > b)
        return a;
    else
        return b;
}

double bsmprice(double S0, double K, double r, double T, double sigma, int type)
{
    double d1, d2;
    
    d1              = (log(S0/K) + (r + sigma*sigma/2)*T)/(sigma*sqrt(T));
    d2              = d1 - sigma*sqrt(T);
    
    if (type == 0)
    {
        return K*exp(-r*T)*normcdf(-d2) - S0*normcdf(-d1);
    }
    else
    {
        return S0*normcdf(d1) - K*exp(-r*T)*normcdf(d2);
    }
}

double AmOptCRR(double S0, double K, double r, double q, double T, double sigma, int N, int type)
{
    double *S, *P, *V, *Q;
    double dt, u, d, a, p, E, I;
    int i, j;
    
    S               = (double*) MEMALLOC((N)*sizeof(double));
    P               = (double*) MEMALLOC((N)*sizeof(double));
    V               = (double*) MEMALLOC((N)*sizeof(double));
    Q               = (double*) MEMALLOC((N)*sizeof(double));
    
    if (!S || !P || !V || !Q)
    {
        if (S) MEMFREE(S);
        if (P) MEMFREE(P);
        if (V) MEMFREE(V);
        if (Q) MEMFREE(Q);
    }
    
    dt                  = T/N;
    u                   = exp(sigma*sqrt(dt));
    d                   = 1/u;
    a                   = exp((r-q)*dt);
    p                   = (a-d)/(u-d);
        
    if (type == 0)
    {
        for (i = 0; i < (N); i++)
        {
            S[i]        = S0*pow(u,N-1)*pow(d,2*i);
            E           = max(K-S[i],0);
            I           = bsmprice(S[i]*exp(-q*dt),K,r,dt,sigma,0);
            P[i]        = max(E,I);
        }
    }
    else
    {
        for (i = 0; i < (N); i++)
        {
            S[i]        = S0*pow(u,N-1)*pow(d,2*i);
            E           = max(S[i]-K,0);
            I           = bsmprice(S[i]*exp(-q*dt),K,r,dt,sigma,1);
            P[i]        = max(E,I);
        }
    }
    
    for (i = N-2; i > -1; i--)
    {
        for (j = 0; j <= i; j++)
        {
            V[j]            = S0*pow(u,i)*pow(d,2*(j));
            E               = (p*P[j]+(1-p)*P[j+1])*exp(-r*dt);
            if (type == 0)
                I           = max(K-V[j],0);
            else
                I           = max(V[j]-K,0);
            
            Q[j]            = max(E,I);
        }
        for (j = 0; j <= i; j++)
        {
            S[j]            = V[j];
            P[j]            = Q[j];
        }
    }
    return P[0];
    
    
    MEMFREE(S);
    MEMFREE(P);
    MEMFREE(Q);
    MEMFREE(V);
    
}

// MEX GATEWAY FUNCTION
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    double S0, K, r, q, T, sigma;
    int N, type;
    double *price;
    
    if(nrhs!=8)
        mexErrMsgTxt("Eight input required.");
    
    S0        = mxGetScalar(prhs[0]);
    K         = mxGetScalar(prhs[1]);
    r         = mxGetScalar(prhs[2]);
    q         = mxGetScalar(prhs[3]);
    T         = mxGetScalar(prhs[4]);
    sigma     = mxGetScalar(prhs[5]);
    N         = (mxGetScalar(prhs[6]) + DOUBLE_EPSILON);
    type      = (mxGetScalar(prhs[7]) + DOUBLE_EPSILON);
    
    plhs[0]   = mxCreateDoubleMatrix(1, 1, mxREAL);
    price     = mxGetPr(plhs[0]);

    price[0]  = AmOptCRR(S0, K, r, q, T, sigma, N, type);
}
