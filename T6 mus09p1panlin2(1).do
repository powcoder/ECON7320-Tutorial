* mus09p1panlin2.do Oct 2009 for Stata version 11
clear

cd "C:\Users\uqcrose3\Desktop\New folder"

cap log close

********** OVERVIEW OF mus09p1panlin2.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 9
* 9.2: PANEL INSTRUMENTAL VARIABLE ESTIMATORS
* 9.3: HAUSMAN TAYLOR ESTIMATOR
* 9.4: ARELLANO-BOND ESTIMATOR 
* 9.5: MIXED LINEAR MODELS
* 9.6: CLUSTERED DATA

* To run you need files
*   mus08psidextract.dta
*   mus09vietnam_ex2.dta
* in your directory
* No Stata user-written commands are used

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

******* 9.2: PANEL IV ESTIMATOR

* Panel IV example: FE with wks instrumented by external instrument ms
use mus08psidextract.dta, clear
xtivreg lwage exp exp2 (wks = ms), fe 

*Weeks worked likely to be endogenous (a choice variable!)
*Those with higher hourly wages would like to work more hours.
*We use marital status as an instrument for weeks worked. The exclusion restriction
*is that being married (or not) does not affect earnings other than through weeks worked.
*We require strict exogeneity our instruments z_it=exp,exp2,ms i.e. 
*E(e_it|a_1,z_i1,...,z_iT)=0

xtivreg lwage exp exp2 (wks = ms), fe vce(cluster id)
*Now with panel-robust standard errors

******* 9.3: HAUSMAN-TAYLOR ESTIMATOR

* Hausman-Taylor example of Baltagi and Khanti-Akom (1990)
use mus08psidextract.dta, clear
xthtaylor lwage occ south smsa ind exp exp2 wks ms union fem blk ed,  ///
  endog(exp exp2 wks ms union ed)

*The within-estimator of the FE model does not identify the effect of the time-invariant
*regressor ed. The Hausman Taylor estimator does, by making additional assumptions (see textbook).
*We must decide which regressors may be correlated with a_i by specifying  endog(exp exp2 wks ms union ed). 
*All regressors are uncorrelated with e_it
*The number of time-varying exogenous regessors must be at least equal to the number of time-invariant endogenous regressors

*HT makes strong assumptions. We can test the overidentifying restrictions using the
*command xtoverid (findit xtoverid):

xtoverid

*Here we do not reject the validity of our overidentifying restrictions.

xthtaylor lwage occ south smsa ind exp exp2 wks ms union fem blk ed, ///
endog(exp exp2 wks ms union ed) vce(boot, reps(400) nodots seed(10101))

*xthtaylor does not allow for panel robust standard errors. We can obtain them using
*a bootstrap instead.


******* 9.4: ARELLANO-BOND ESTIMATOR

*Panel data allow us to estimate dynamic models in which one or more of the regressors
* can be past values of y_it. The AR(p) model is:

*y_it=rho_1 y_it-1 + rho_2 y_it-2+...rho_p y_it-p+x_it beta+a_i+e_it

*The lagged values of the outcome are correlated with a_i, hence endogenous. As usual,
*we can transform them out. Arrellano-Bond estimator uses first differences (Why?):

*(y_it-y_it-1)=rho_1 (y_it-1-y_it-2) + rho_2 (y_it-2-y_it-3)+...rho_p (y_it-p-y_it-p-1)+(x_it-x_it-1) beta+(e_it-e_it-1)
*Under strict exogeneity of x_it and no serial correlation of e_it, valid instruments are 
*z_it=[x_it,x_it-1,...,y_it-2,y_it-3,...]
*Note: y_it-1 is correlated with (e_it-e_it-1), whilst y_it-2 is not if e_it does not have
*serial correlation. We use first differences as it permits the use of y_it-2,y_it-3,... as instruments. The within approach would not.

* 2SLS or one-step GMM for a pure time-series AR(2) panel model
use mus08psidextract.dta, clear
xtabond lwage, lags(2) vce(robust)

*Here we estimate a simple AR(2) model with no x_it and instruments y_it-2,...,y_1
*Standard errors are panel-robust.

* Optimal or two-step GMM for a pure time-series AR(2) panel model
xtabond lwage, lags(2) twostep vce(robust)

*Here we do two-step GMM with an optimal weight matrix

* Reduce the number of instruments for a pure time-series AR(2) panel model
xtabond lwage, lags(2) vce(robust) maxldep(1)

*Here we only use y_it-2 as an instrument instead of y_it-2,...,y_1. This can improve performance
*in finite samples, since too many instruments is known to be problematic.

* Optimal or two-step GMM for a dynamic panel model
xtabond lwage occ south smsa ind, lags(2) maxldep(3)     ///
  pre(wks,lag(1,2)) endogenous(ms,lag(0,2))              ///
  endogenous(union,lag(0,2)) twostep vce(robust) artests(3)
  
*Here we include regressors. 
*We treat wks as predetermined: E(wks_it e_is)=0 for s>=t
*We treat ms and union as endogenous and use two lags as instruments

* Test whether error is serially correlated
estat abond

*We assumed no serial correlation in e_it in order to use y_it-2,... as instruments
*Here we test this assumption.
*If e_it are not serially correlated then (e_it-e_it-1) is correlated with (e_it-1-e_it-2)
*but not with further lags such as (e_it-2-e_it-3)
*Here we do not reject H0: No serial correlation at the 0.05 level

* Test of overidentifying restrictions (first estimate with no vce(robust))
quietly xtabond lwage occ south smsa ind, lags(2) maxldep(3) ///
  pre(wks,lag(1,2)) endogenous(ms,lag(0,2))              ///
  endogenous(union,lag(0,2)) twostep artests(3)
estat sargan

*As ever, when doing IV with more instruments than regressors we can test overidentifying
*restrictions.
*Here we do not reject the null that the overidentifying restrictions are valid at the
*0.05 level... but it is close!


********** CLOSE OUTPUT
