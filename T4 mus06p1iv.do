* mus06p1iv.do  Oct 2009 for Stata version 11

clear

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T4"

cap log close

********** OVERVIEW OF mus06p1iv.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 6
* 6.3: INSTRUMENTAL VARIABLES EXAMPLE
* 6.4: WEAK INSTRUMENTS
* 6.5: BETTER INFERENCE WITH WEAK INSTRUMENTS
* 6.6: 3SLS SYSTEMS ESTIMATION

* To run you need files
*   mus06data.dta    
* in your directory

* Stata user-written commands
*   condivreg
*   ivreg2
*   jive
* are used

********** SETUP **********

set more off
version 11
clear all
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION **********

* The original data is from MEPS over 65 similar to chapter 3

********** 6.3: INSTRUMENTAL VARIABLES EXAMPLE

* Read data, define global x2list, and summarize data
use mus06data.dta
global x2list totchr age female blhisp linc 
summarize ldrugexp hi_empunion $x2list

* Summarize available instruments for the estimation sample (we use log-income
* as a regressor so we require it to not be missing. That is why there is `if linc!=.')
summarize ssiratio lowincome multlc firmsz if linc!=.

* In theory, we should use all of them as this leads to the most efficient 
* estimator (asymptotically)
* In practice, it may lead to larger small sample bias which increases in
* the number of instruments (Hahn and Hausman, 2002)

* IV estimation of a just-identified model with single endog regressor
ivregress 2sls ldrugexp (hi_empunion = ssiratio) $x2list, vce(robust) first

* The first option to show the first stage. ssiratio is negatively associated with
* insurance as expected and highly significant
* The IV estimate on hi_empunion is large and negative. Insured individuals are
* estimated to have 90% lower out of pocket expenses on drugs

* Compare 5 estimators and variance estimates for overidentified models
global ivmodel "ldrugexp (hi_empunion = ssiratio multlc) $x2list"
quietly ivregress 2sls $ivmodel, vce(robust)
estimates store TwoSLS
quietly ivregress gmm  $ivmodel, wmatrix(robust) 
estimates store GMM_het
quietly ivregress gmm  $ivmodel, wmatrix(robust) igmm
estimates store GMM_igmm
quietly ivregress gmm  $ivmodel, wmatrix(cluster age) 
estimates store GMM_clu
quietly ivregress 2sls  $ivmodel
estimates store TwoSLS_def
estimates table TwoSLS GMM_het GMM_igmm GMM_clu TwoSLS_def, b(%9.5f) se  

* Here we use ssiratio and multlc as instruments. We compare the 2SLS estimator with robust standard
* errors with the optimal two-step GMM estimator under heteroskedasticity (GMM_het), the iterated
* GMM estimator (GMM_igmm) which uses more than two steps and the optimal two-step GMM estimator
* with standard errors clustered on age (GMM_clu), which allows for dependence between the 
* errors of individuals of the same age. The last estimator is the 2SLS estimaor without
* robust standard errors.

* Compared with the just identified case, the estimated effect of insurance
* has increased in magnitude. The standard error has decreased due to the efficiency gain
* from a stronger first stage (we have one more instrument).

* There is little difference between the estimators.

* Obtain OLS estimates to compare with preceding IV estimates
regress ldrugexp hi_empunion $x2list, vce(robust) 

* OLS suggests that insurance increases expenditure on drugs! This is because of the bias
* Those who expect to spend more on drugs are more likely to purchase insurance, and seem
* to spend more on drugs! The IV approach deals with this problem.

* Robust Durbin-Wu-Hausman test of endogeneity implemented by estat endogenous
ivregress 2sls ldrugexp (hi_empunion = ssiratio) $x2list, vce(robust)
estat endogenous

* We return to the just identified model and test for endogeneity of the regressors
* Unsurprisingly, we reject H0: Exogenous regressors

* Robust Durbin-Wu-Hausman test of endogeneity implemented manually
quietly regress hi_empunion ssiratio $x2list
quietly predict v1hat, resid
quietly regress ldrugexp hi_empunion v1hat $x2list, vce(robust)
test v1hat 

* Now back to the overidentified case. Test of overidentifying restrictions following ivregress gmm
quietly ivregress gmm ldrugexp (hi_empunion = ssiratio multlc) ///
  $x2list, wmatrix(robust) 
estat overid

* The validity of an instrument cannot be tested in the just identified case.
* But it can in the overidentified case
* To do this, we use a Hansen test
* H0: E[Z'(y-X*beta)]=0
* Here we do not reject H0
* See p191 of textbook for details

* Test of overidentifying restrictions when we use all instruments
ivregress gmm ldrugexp (hi_empunion = ssiratio lowincome multlc firmsz) ///
  $x2list, wmatrix(robust) 
estat overid

* Different result with all of our instruments! But our parameter estimate is
* quite similar (-0.8) instead of (-0.9)

* Regression with a dummy variable regressor
treatreg ldrugexp $x2list, treat(hi_empunion = ssiratio $x2list)

* Our endogenous regressor is binary
* Makes sense to model the first stage using a model for binary variables
* Here we use probit for the first stage
* We get a larger effect of insurance, closer to -1.41

********** 6.4: WEAK INSTRUMENTS

* Correlations of endogenous regressor with instruments
correlate hi_empunion ssiratio lowincome multlc firmsz if linc!=.

* Quite low gross correlations of endogenous variable with instrument

* Weak instrument tests - just-identified model
quietly ivregress 2sls ldrugexp (hi_empunion = ssiratio) $x2list, vce(robust)
estat firststage, forcenonrobust all  

* We have the R-squared from the first stage, the partial R-squared which measures
* the effect of the instruments net of the other exogenous regressors and the first stage F
* statistic. The first stage F-statistic is very large (much larger than the baseline of 10)
* Stock and Yogo test strongly reject the null hypothesis of weak instruments since the minimum eigenvalue
* statistic is 183.98 compared to critical values of 16-5

* Weak instrument tests - two or more overidentifying restrictions
quietly ivregress gmm ldrugexp (hi_empunion = ssiratio lowincome multlc firmsz) ///
   $x2list, vce(robust)
estat firststage, forcenonrobust

* We reach the same conclusion when we use all of our instruments

* Compare 4 just-identified model estimates with different instruments
quietly regress ldrugexp hi_empunion $x2list, vce(robust)
estimates store OLS0
quietly ivregress 2sls ldrugexp (hi_empunion=ssiratio) $x2list, vce(robust)
estimates store IV_INST1
quietly estat firststage, forcenonrobust
scalar me1 = r(mineig)
quietly ivregress 2sls ldrugexp (hi_empunion=lowincome) $x2list, vce(robust)
estimates store IV_INST2
quietly estat firststage, forcenonrobust
scalar me2 = r(mineig)
quietly ivregress 2sls ldrugexp (hi_empunion=multlc) $x2list, vce(robust) 
estimates store IV_INST3
quietly estat firststage, forcenonrobust
scalar me3 = r(mineig)
quietly ivregress 2sls ldrugexp (hi_empunion=firmsz) $x2list, vce(robust)
estimates store IV_INST4
quietly estat firststage, forcenonrobust
scalar me4 = r(mineig)
estimates table OLS0 IV_INST1 IV_INST2 IV_INST3 IV_INST4, b(%8.4f) se  
display "Minimum eigenvalues are:     " me1 _s(2) me2 _s(2) me3 _s(2) me4

* We find very different results of IV depending on which instrument we use
* The first instrument (ssiratio) appears to be the strongest and gives the most
* plausible result.

* THE REST IS FOR YOUR OWN INDEPENDENT STUDY. SEE CH6 OF COURSE TEXTBOOK.

********** 6.5: BETTER INFERENCE WITH WEAK INSTRUMENTS

* Conditional test and confidence intervals when weak instruments 
condivreg ldrugexp (hi_empunion = ssiratio) $x2list, lm ar 2sls test(0)

* Variants of IV Estimators: 2SLS, LIML, JIVE, GMM_het, GMM-het using IVREG2
global ivmodel "ldrugexp (hi_empunion = ssiratio lowincome multlc firmsz) $x2list"
quietly ivregress 2sls $ivmodel, vce(robust)
estimates store TWOSLS
quietly ivregress liml $ivmodel, vce(robust)
estimates store LIML
quietly jive $ivmodel, robust
estimates store JIVE
quietly ivregress gmm $ivmodel, wmatrix(robust) 
estimates store GMM_het
quietly ivreg2 $ivmodel, gmm robust
estimates store IVREG2
estimates table TWOSLS LIML JIVE GMM_het IVREG2, b(%7.4f) se 

********** 6.6: 3SLS SYSTEMS ESTIMATION

* 3SLS estimation requires errors to be homoskedastic
reg3 (ldrugexp hi_empunion totchr age female blhisp linc) ///
  (hi_empunion ldrugexp totchr female blhisp ssiratio)


********** CLOSE OUTPUT **************
