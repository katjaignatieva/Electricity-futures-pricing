%% This script recreates all graphs and tables from the paper
clear all;
clc;

% Figure 1: Time series of spot price and logarithm of the spot price
fig1 = figDataNew();

% Table 1: Summary statistics of the spot price and the logarithm of the spot price
tab1 = tabData();

% Table 2: Parameter estimates of the spot price’s deterministic component
tab2 = tabDeterministicSpot();

% Figure 2: Time series of deterministic and stochastic components
fig2 = figDeterministic();

% Table 3: Summary statistics of futures prices
tab3 = tabFuturesData();

% Figure 3: Futures market prices
fig3 = figFuturesData();

% Table 4: Parameter estimates for the four specifications of our framework
[tab4_pv,tab4_stderr] = tabParameters();

% Figure 4: Filtered values of the long-run level, the volatility, and negative jump intensity for the full specification
% Figure 5: Filtered values of the innovations of the stochastic component of the electricity spot price for the full specification
% Figure 6: Filtered values of the positive spot price jumps, negative spot price jumps, variance jumps, and negative jump intensity jumps for the full specification
[fig4,fig6,fig5] = figEstimation();

% Table 5: In-sample root-mean-square errors per maturity and volatility level bins
% Table 6: Diebold–Mariano test statistics for in-sample weekly root-mean-square errors
% Table 7: Out-of-sample root-mean-square errors per maturity and volatility level bins
% Table 8: Diebold–Mariano test statistics for out-of-sample weekly root-mean-square errors
[tab5,tab6,tab7,tab8] = tabPricingErrors();

% Figure 7: Futures market and model prices for the full specification
fig7 = figPricingErrors();

% Figure 8: Futures market and model prices term structure for four representative dates
fig8 = figTermStructure();

% Table 9: Radon–Nikodym parameters implied by the estimated parameters
tab9 = tabRND();





