* mus08p1panlin.do Oct 2009 for Stata version 11

cap log close

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T5"

********** OVERVIEW OF mus08p1panlin.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 8
* 8.3: PANEL-DATA SUMMARY
* 8.4: POOLED OR POPULATION-AVERAGED ESTIMATORS
* 8.5: WITHIN ESTIMATOR
* 8.6: BETWEEN ESTIMATOR
* 8.7: RANDOM EFFECTS ESTIMATOR
* 8.8: COMPARISON OF ESTIMATORS 
* 8.9: FIRST DIFFERENCE ESTIMATOR
* 8.10: LONG PANELS
* 8.11: PANEL-DATA MANAGEMENT

* To run you need files
*   mus08psidextract.dta
*   mus08cigar.dta
*   mus08cigarwide.dta
* in your directory
* Stata user-written command
*   xtscc
* is used

********** SETUP **********

set more off
version 11
clear all
set memory 30m
set linesize 90
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION **********

* mus08psidextract.dta
* PSID. Same as Stata website file psidextract.dta
* Data due to  Baltagi and Khanti-Akom (1990) 
* This is corrected version of data in Cornwell and Rupert (1988).
* 595 individuals for years 1976-82

* mus08cigar.dta
* Due to Baltagi et al. (2001)
* Panel on 46 U.S. states over 30 years 1963-92

* mus08cigarwide.dta is a smaller wide from version of mus08cigar.dta

******* 8.3: PANEL-DATA SUMMARY

* Read in dataset and describe
use mus08psidextract.dta, clear
describe

* Summary of dataset
summarize

* No missing observations

* Organization of dataset
list id t exp wks occ in 1/3, clean

* Data are in long format 

* Declare individual identifier and time identifier
xtset id t

* Panel description of dataset
xtdescribe 

* N=595, T=7
* Balanced panel (i.e. we observe everybody T=7 times)

* Panel summary statistics: within and between variation
xtsum id t lwage ed exp exp2 wks south tdum1

* Within variation is variation for a given individual over time: 
* s^2_W=(NT-1)^(-1)\sum_i\sum_t (x_it-xbar_i)^2
* Between variation is variation between individuals:
* s^2_B=(N-1)^(-1)\sum_i (xbar_i-xbar)^2
* Overall variation combines the two:
* s^2_O=(NT-1)^(-1) \sum_i\sum_t (x_it-xbar)^2
* It can be showed that s^2_O is approximately s^2_W+s^2_O

* Time invariant variables: id, ed (zero within variance)
* Cross section invariant variables: t, tdum1 (zero between variance)

* Panel tabulation for a variable
xttab south

* 71% of observations have south=0
* 72% of individuals had south=0 at least once
* 99% of people who ever had south=0 always had south=0

* Transition probabilities for a variable
xttrans south, freq

* Estimate of P(South in t|South in t-1) is 0.9923

// Following simpler command not included in book
* Simple time-series plot for each of 20 individuals
quietly xtline lwage if id<=20, overlay 

* plot log wage over time for 20 individuals
* wages steadily rising, strongly autocorrelated

* Simple time-series plot for each of 20 individuals
quietly xtline lwage if id<=20, overlay legend(off) saving(lwage, replace)
quietly xtline wks if id<=20, overlay legend(off) saving(wks, replace)
graph combine lwage.gph wks.gph, iscale(1)
quietly graph export mus08timeseriesplot.eps, replace

*Combine time series plot of log wage and weeks worked for 20 individuals

* Scatterplot, quadratic fit and nonparametric regression (lowess)
graph twoway (scatter lwage exp, msize(small) msymbol(o))              ///
  (qfit lwage exp, clstyle(p3) lwidth(medthick))                       ///
  (lowess lwage exp, bwidth(0.4) clstyle(p1) lwidth(medthick)),        ///
  plotregion(style(none))                                              ///
  title("Overall variation: Log wage versus experience")               ///
  xtitle("Years of experience", size(medlarge)) xscale(titlegap(*5))   /// 
  ytitle("Log hourly wage", size(medlarge)) yscale(titlegap(*5))       ///
  legend(pos(4) ring(0) col(1)) legend(size(small))                    ///
  legend(label(1 "Actual Data") label(2 "Quadratic fit") label(3 "Lowess"))
graph export mus08scatterplot.eps, replace

* Overall scatter plot of log wage and experience with quadratic fit and non-paramtetrics
* fit

* Scatterplot for within variation
preserve
xtdata, fe
graph twoway (scatter lwage exp) (qfit lwage exp) (lowess lwage exp),  ///
  plotregion(style(none)) title("Within variation: Log wage versus experience")
restore
graph export mus08withinplot.eps, replace

* preserve the data (so we can return to it later)
* then use xtdata,fe to perform repalce x_it with x_it-xbar_i
* then repeat the plot, this time using within variation only
* then restore the data to its original form
* experience looks to have a linear effect when we control for individual heterogeneity

* Pooled OLS with cluster-robust standard errors

regress lwage exp exp2 wks ed, vce(cluster id)

* OLS regression: y_it=x_it'*beta+u_it
* consistent for beta if x_it is uncorrelated with u_it
* clustering by individual allows for cov(u_it,u_is) to be nonzero
* VCE estimate is consistent as number of clusters (here it is N) goes to infinity
* uses between and within variation
* everything has the expected sign

* Pooled OLS with incorrect default standard errors
regress lwage exp exp2 wks ed 

* This assumes that cov(u_it,u_is)=0! Not plausible.
* Standard errors are smaller because we treat all of our observations
* as independent

* First-order autocorrelation in a variable
sort id t  
correlate lwage L.lwage

* correlation of y_it with y_it-1
* strong wage correlation over time

* Autocorrelations of residual 
quietly regress lwage exp exp2 wks ed, vce(cluster id)
predict uhat, residuals
forvalues j = 1/6 {
     quietly corr uhat L`j'.uhat
     display "Autocorrelation at lag `j' = " %6.3f r(rho) 
     }
	 
* correlation of uhat_it with uhat_it-1,uhat_it-2,...
* expected if u_it=a_i+e_it with i.i.d. e_it

* First-order autocorrelation differs in different year pairs
forvalues s = 2/7 {
     quietly corr uhat L1.uhat if t == `s'
     display "Autocorrelation at lag 1 in year `s' = " %6.3f r(rho) 
     }
	 
 * is autocorrelation stable over time? 
 * expected to be if it comes from u_it=a_i+e_it with i.i.d. e_it

******* 8.4: POOLED OR POPULATION-AVERAGED ESTIMATORS

* Population-averaged or pooled FGLS estimator with AR(2) error
xtreg lwage exp exp2 wks ed, pa corr(ar 2) vce(robust) nolog

* pooled or population average estimators perform GLS
* allow for serial correlation of u_it
* here we use feasible GLS under the assumption that u_it=rho_1 u_it-1+rho_2 u_it-2+v_it
* consistent if x_it is not correlated with u_it (RE model)
* standard errors smaller than our earlier OLS estimator (GLS more efficient)

* Estimated error correlation matrix after xtreg, pa
matrix list e(R)

* still we are left with strong autocorrelation of uhat_it

******* 8.5: WITHIN ESTIMATOR

* Within or FE estimator with cluster-robust standard errors
xtreg lwage exp exp2 wks ed, fe vce(cluster id)

* Within estimation transforms the model to get rid of a_i
* Allows for correlation of x_it with a_i
* Here a_i could be interpreted as ability
* We lose any variables that are fixed over time (education)
* Maintain clustered standard errors

* LSDV model fit using areg with cluster-robust standard errors
areg lwage exp exp2 wks ed, absorb(id) vce(cluster id)

* Now we use the LSDV model, including N dummy variables for the a_i
* Exact same coefficient estimate as the within estimator (by construction)
* areg command does regression with dummies defined by absorb() and does not report the dummy coefficients

******* 8.6: BETWEEN ESTIMATOR

* Between estimator with default standard errors
xtreg lwage exp exp2 wks ed, be

* Estimates the model:
* ybar_i=xbar_i'*beta + ubar_i
* Requires ubar_i to be uncorrelated with xbar_i

// Following gives heteroskedasrtic-robust se's for between estimator
* xtreg lwage exp exp2 wks ed, be vce(boot, reps(400) seed(10101) nodots)

******* 8.7: RANDOM EFFECTS ESTIMATORS

* Random-effects estimator with cluster-robust standard errors
xtreg lwage exp exp2 wks ed, re vce(cluster id) 

* Estimates the random effects model with clustered standard errors
* Consistent if x_it uncorrelated with a_i and e_it

******* 8.8: COMPARISON OF ESTIMATORS

* Compare OLS, BE, FE, RE estimators, and methods to compute standard errors
global xlist exp exp2 wks ed 
quietly regress lwage $xlist, vce(cluster id)
estimates store OLS_rob
quietly xtreg lwage $xlist, be
estimates store BE
quietly xtreg lwage $xlist, fe 
estimates store FE
quietly xtreg lwage $xlist, fe vce(robust)
estimates store FE_rob
quietly xtreg lwage $xlist, re
estimates store RE
quietly xtreg lwage $xlist, re vce(robust)
estimates store RE_rob
estimates table OLS_rob BE FE FE_rob RE RE_rob,  ///
  b se stats(N r2 r2_o r2_b r2_w sigma_u sigma_e rho) b(%7.4f)

* Hausman test assuming RE estimator is fully efficient under null hypothesis
hausman FE RE, sigmamore

* Under RE, both FE and RE estimators are consistent
* Under FE, only FE estimator is
* So we can test H0: RE by comparing estimated beta from RE with that of FE (Wald test)
* Here we reject RE

* Robust Hausman test using method of Wooldridge (2002)
quietly xtreg lwage $xlist, re
scalar theta = e(theta)
global yandxforhausman lwage exp exp2 wks ed
sort id
foreach x of varlist $yandxforhausman {
  by id: egen mean`x' = mean(`x')
  generate md`x' = `x' - mean`x'
  generate red`x' = `x' - theta*mean`x'
  }
quietly regress redlwage redexp redexp2 redwks reded mdexp mdexp2 mdwks, vce(cluster id)
test mdexp mdexp2 mdwks

* Hausman test requires RE to be efficient or that a_i and e_it are i.i.d.
* Here we do a test which does not require that assumption
* We still reject RE

* Prediction after OLS and RE estimation
quietly regress lwage exp exp2 wks ed, vce(cluster id)
predict xbols, xb
quietly xtreg lwage exp exp2 wks ed, re  
predict xbre, xb
predict xbure, xbu
summarize lwage xbols xbre xbure
correlate lwage xbols xbre xbure

* Here we can do prediction after RE and OLS
* xb asks for x_it*betahat
* After RE model, xbu asks for x_it*betahat+ahat_i

******* 8.9: FIRST DIFFERENCE ESTIMATOR

sort id t
* First-differences estimator with cluster-robust standard errors
regress D.(lwage exp exp2 wks ed), vce(cluster id) noconstant

* Larger standard errors than FE.
* Best to avoid in practice
