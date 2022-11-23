* To run you need files
*   mus03data.dta 
* in your directory
* Stata user-written commands esttab and estadd are used

********** SETUP **********

set more off
version 11
clear all
set linesize 82
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION **********

* File mus03data is extract from MEPS

************ 3.2: DATA SUMMARY STATISTICS

* Variable description for medical expenditure dataset

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T7"

use mus03data.dta
log using e6300_prac-bstrap_new.txt, text replace 
describe totexp ltotexp posexp suppins phylim actlim totchr age female income

* OLS regression with heteroskedasticity-robust standard errors
regress ltotexp suppins phylim actlim totchr age female income, vce(robust)

************ Data Selection 
keep ltotexp suppins totchr age 
quietly save bootdata.dta, replace 
regress ltotexp suppins totchr age, vce(robust)
regress ltotexp suppins totchr age

* Bootstrap estimate of the standard error of the coefficient of variation
use bootdata, clear
bootstrap coeffvar=(r(sd)/r(mean)), reps(400) seed(10101) nodots   ///
   nowarn saving(coeffofvar, replace): summarize ltotexp
 
 * Bootstrap standard errors for different reps and seeds 
quietly regress ltotexp suppins totchr , vce(boot, reps(50) seed(10101))
estimates store boot50
regress ltotexp suppins totchr , vce(boot, reps(200) seed(10101))
estimates store boot200
quietly regress ltotexp suppins totchr , vce(robust)
estimates store robust
estimates table boot50 boot200 robust, b(%8.5f) se(%8.5f)
 
* Option vce(boot, cluster) to compute cluster-bootstrap standard errors
regress ltotexp suppins totchr age , vce(boot, cluster(age) reps(400) seed(10101) nodots)

* Bootstrap confidence intervals: normal-based (beta_hat+- 1.96*se_boot), percentile (0.025 percentile of beta_hat_boot,0.975 percentile of beta_hat_boot)
quietly regress ltotexp suppins totchr age , vce(boot, reps(999) seed(10101))
estat bootstrap, normal percentile

* List the average of the bootstrap estimates of beta
matrix list e(b_bs)

 ****** BOOTSTRAP PAIRS USING THE BOOTSTRAP COMMAND

* Bootstrap command applied to Stata estimation command
bootstrap, reps(400) seed(10101) nodots noheader: regress ltotexp suppins totchr age

* Bootstrap standard-error estimate of the standard error of a coeff estimate
bootstrap _b _se, reps(400) seed(10101) nodots: regress ltotexp suppins totchr age 
 
****** : BOOTSTRAPS WITH ASYMPTOTIC REFINEMENT

* Percentile-t for a single coefficient: Bootstrap the t statistic
use bootdata, clear
regress ltotexp age, vce(robust)
local theta = _b[age] 
local setheta = _se[age]
bootstrap tstar=((_b[age]-`theta')/_se[age]), seed(10101)        ///
  reps(999) nodots saving(percentilet, replace): regress ltotexp age, ///
  vce(robust)

* Percentile-t p-value for symmetric two-sided Wald test of H0: theta = 0
use percentilet, clear
quietly count if abs(`theta'/`setheta') < abs(tstar)
display "p-value = " r(N)/_N

* Percentile-t critical values and confidence interval
_pctile tstar, p(2.5,97.5) 
scalar lb = `theta' + r(r1)*`setheta'
scalar ub = `theta' + r(r2)*`setheta'
display "2.5 and 97.5 percentiles of t* distn: " r(r1) ", " r(r2) _n ///
    "95 percent percentile-t confidence interval is  (" lb ","  ub ")"
  

* Program for residual bootstrap for OLS with iid errors
use bootdata, clear
quietly regress ltotexp age 
predict uhat, resid
keep uhat
save residuals, replace
program bootresidual
  version 11 
  drop _all
  use residuals
  bsample                     
  merge using bootdata   
  regress ltotexp age
  predict xb
  generate ystar =  xb + uhat
  regress ystar age
end

* Check the program by running once
bootresidual

* Residual bootstrap for the parameters
simulate _b, seed(10101) reps(400) nodots: bootresidual
summarize

log close
 
********** CLOSE OUTPUT

 


