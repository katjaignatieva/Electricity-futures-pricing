README
 
Replication code for "The stochastic behavior of electricity prices under scrutiny: Evidence from spot and futures markets"

Overview
This zip file contains the MATLAB replication code for the paper "The stochastic behavior of electricity prices under scrutiny: Evidence from spot and futures markets." This article proposes a stochastic volatility jump-diffusion model for pricing electricity derivative contracts. The main objective is to develop a model that effectively captures the characteristics and stylized facts of the electricity spot market, such as mean reversion, changing expectations in the spot price’s long-run level, seasonality, extreme volatility, price spikes, and time-varying jump intensity. We employ a particle filter that relies on both spot prices and futures data to estimate model parameters. The results demonstrate that incorporating the aforementioned features is crucial for accurately fitting both spot and futures prices, as evidenced by data from the Australian electricity market.

Note that, as the futures data are proprietary, we cannot include them along with this submission. As a proof of concept, and to show how our replication code works, we have included our main codes along with a very small sample of futures prices. The results generated will thus be different than those reported in the manuscript as the futures dataset is incomplete. All the objects in results/ are those based on all the futures prices.

The replication package is organized as follows:

├── RUNTASKS_SVJ.m 					# Main estimation tasks for the SVJ specification of our model
├── RUNTASKS_SVJDI.m 					# Main estimation tasks for the SVJDI specification of our model
├── RUNTASKS_SVJLRL.m 					# Main estimation tasks for the SVJLRL specification of our model
├── RUNTASKS_SVJDILRL.m 				# Main estimation tasks for the SVJDILRL specification of our model
├── FIGTABS.m 							# Script generating all tables and figures (based on estimated results)
│
├── data/
│   ├── DailyRV.mat           			# Realized volatility computed from high-frequency spot prices
│   ├── DailySpotPrices.mat          	# Daily spot prices
│   └── FuturesPrices.mat     			# Very small sample of futures prices
│
├── figtabs/							# Various codes to generate tables and figures (see FIGTABS.m)
│
├── lib/								# Various libraries and useful codes
│
├── results/ 							# Various outputs and model estimation results for each model (SVJ, SVJDI, SVJLRL, SVJDILRL)
│
├── SVJ.m 								# MATLAB class containing all important functions for the SVJ specification
├── SVJDI.m 							# MATLAB class containing all important functions for the SVJDI specification
├── SVJLRL.m 							# MATLAB class containing all important functions for the SVJLRL specification
├── SVJDILRL.m 						# MATLAB class containing all important functions for the SVJDILRL specification
├── ParticleFilter_SVJ.m 				# MATLAB class containing all important particle filtering functions for the SVJ specification
├── ParticleFilter_SVJDI.m 			# MATLAB class containing all important particle filtering functions for the SVJDI specification
├── ParticleFilter_SVJLRL.m 			# MATLAB class containing all important particle filtering functions for the SVJLRL specification
├── ParticleFilter_SVJDILRL.m 			# MATLAB class containing all important particle filtering functions for the SVJDILRL specification
├── startup.m 							# Overwrites MATLAB startup.m with project-specific paths to be included
├── getDeterministicSpot.m 			# Function providing values of the estimated deterministic component
├── errorFutures.m 					# Function providing futures errors and prices 
│
├── README.txt                    		# This README file
