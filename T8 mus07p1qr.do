* mus07p1qr.do  Oct 2009 for Stata version 11

cap log close

* To speed up program reduce number in reps() for bsqreg and sqreg
* the program usually uses 400
* and reduce number in rep() for qcount

********** OVERVIEW OF mus07p1qr.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 7
* 7.3: QUANTILE REGRESSION FOR MEDICAL EXPENDITURES DATA
* 7.4: QUANTILE REGRESSION FOR GENERATED HETEROSKEDASTIC DATA
* 7.5: QUANTILE REGRESSION FOR COUNT DATA

* To run you need files
*   mus03data.dta 
*   mus07qrcnt.dta   
* in your directory
* Stata user-written commands
*    qplot
*    grqreg  
* are used and need to be user-installed in Stata

********** SETUP **********

set more off
version 11
clear all
set scheme s1mono  /* Graphics scheme */

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T8"

********** 7.3: QUANTILE REGRESSION FOR MEDICAL EXPENDITURES DATA

* Read in log of medical expenditures data and summarize
use mus03data.dta, clear
drop if ltotexp == . 
summarize ltotexp suppins totchr age female white

* Quantile plot for ltotexp using user-written command qplot
qplot ltotexp, recast(line) scale(1.5)
quietly graph export mus07fig1_qltotexp.eps, replace 
* Plots the quantiles of the dependent variable. For example, the median is approximately
* 8.


* Basic quantile regression for q = 0.5
qreg ltotexp suppins totchr age female white

* Obtain multiplier to convert QR coeffs in logs to AME in levels. 
quietly predict xb
generate expxb = exp(xb)
quietly summarize expxb
display "Multiplier of QR in logs coeffs to get AME in levels = " r(mean)
* We have a log-linear model so our model is Q_q(ln y|x)=x'b_q
* Hence, by the equivariance property Q_q(y|x)=exp(x'b_q)
* So the ME on y is dQ_q(y|x)/x_j=exp(x'b_q)b_qj
* So the AME is N^(-1)\sum_i exp(x_i'b_q)b_qj
* We obtain an estimator of exp(x'b_q) using the estimated b_q, which is expxb above
* We can use this to estimate the AME. For example, for totchr the AME is 3746.7*0.3943=1477
* An additional chronic condition increases the conditional median of expenditure by $1477

* Compare (1) OLS; (2-4) coeffs across quantiles; (5) bootstrap SEs
quietly regress ltotexp suppins totchr age female white   
estimates store OLS
quietly qreg ltotexp suppins totchr age female white, quantile(.25)  
estimates store QR_25
quietly qreg ltotexp suppins totchr age female white, quantile(.50) 
estimates store QR_50
quietly qreg ltotexp suppins totchr age female white, quantile(.75) 
estimates store QR_75
set seed 10101 
quietly bsqreg ltotexp suppins totchr age female white, quant(.50) reps(400) 
estimates store BSQR_50 
estimates table OLS QR_25 QR_50 QR_75 BSQR_50, b(%7.3f) se  

* Test for heteroskedasticity in linear model using estat hettest
quietly regress ltotexp suppins totchr age female white
estat hettest suppins totchr age female white, iid
*Our quantile regressions show that b_q varies with the quantile q.
*This is evidence of heteroskedasticity. We confirm it by testing formally.

* Simultaneous QR regression with several values of q
set seed 10101
sqreg ltotexp suppins totchr age female white, q(.25 .50 .75) reps(400)
*QR regression at 3 quantiles with bootstrapped standard errors.
*Allows us to obtain the full covariance matrix (i.e. 3Kx3K) matrix for b_.25,b_.5,b_.75 
*where K is the dimension of b_q
*This permits us to conduct hypothesis tests such as the test below. 

* Test of coefficient equality across QR with different q
test [q25=q50=q75]: suppins
*We reject the null hypothesis that suppins has the same coefficient at different quantiles

* Plots of each regressor's coefficients as quantile q varies
quietly bsqreg ltotexp suppins totchr age female white, quantile(.50) reps(400)
label variable suppins "=1 if supp ins"
label variable totchr "# of chronic condns"
grqreg, cons ci ols olsci scale(1.1)
quietly graph export mus07fig3_qrcoeff.eps, replace
*Quantile plots of the coefficients of the regressors and their confidence intervals.
*OLS estimator and confidence interval is also included (the horizontal line).
*Clear heterogeneous effects of suppins and totchr over the distribution of ltotexp.


********** CLOSE OUTPUT **********
