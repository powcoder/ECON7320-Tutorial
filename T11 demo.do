* mus17p1cnt.do Oct 2009 for Stata version 11

********** OVERVIEW OF mus17p1cnt.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 17
* This program analyzes the data used in chapter 17

* in your directory
* Stata user-written commands
*   spost9_ado     // For prvalue, prcount, listcoef in section 17.3, 17.4
*   hplogit        // For hurdle model in section 17.3
*   hnblogit       // For hurdle model in section 17.3
*   fmm            // For finite mixture models in section 17.3
* are used

********** SETUP **********

set more off
*version 11
clear all
set scheme s1mono  /* Graphics scheme */

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2019\T11"
 
use qreg0902.dta, clear
global xlist ltotexp age farm urban98 male
summarize lmedexp $xlist

*FIT A FINITE MIXTURE MODEL WITH NO REGRESSORS
fmm 2, vce(robust): regress lmedexp 
*Here we fit a finite mixture model for lmedexp with two normal components
*That is we suppose that f(lmedexp)=pi_1*N(mu_1,sigma^2_1)+(1-pi_1)*N(mu_2,sigma^2_2)
*and use the EM algorithm to estimatate pi_1,mu_1,sigma^2_1,mu_2,sigma^2_2
*The first panel relates to the class probabilities, but is hard to interpret. The second
*and third panels report the estimated mu and sigma^2 for each class and standard errors.

*CLASS PROBABILITIES
estat lcprob
*Here we see that the estimate of pi_1 is 0.693. We also obtain estimated standard
*errors.
*ESTIMATES OF MU
estat lcmean
*Here we see a summary of the mu in each class

*Fitted density
sort lmedexp
predict den, density marginal
histogram lmedexp, bin(80) addplot(line den lmedexp)

*ADDING COVARIATES
fmm 2, vce(robust): regress lmedexp $xlist
*Here we fit a finite mixture model for lmedexp with two normal components
*That is we suppose that f(lmedexp|x)=pi_1*N(beta_1'*x,sigma^2_1)+(1-pi_1)*N(beta_2'*x,sigma^2_2)

estat lcprob

estat lcmean

*Estimate P(class_i=c|y_i,x_i)
predict pr*, classposteriorpr
sum pr*
hist pr1, title("Distribution of posterior class probability")

*Predict fitted values of lmedexp for each class
predict mu*, mu
sum mu*
*Notice the relationship with estat lcmean
twoway (histogram mu1, width(.25) color(navy%25)) (histogram mu2, width(.25) color(maroon%25))

*MARGINAL EFFECTS: SIMILAR TO PROBIT/LOGIT SYNTAX
quietly fmm 2: regress lmedexp $xlist
margins, eyex(ltotexp) atmean
*Elasticity of E[lmedexp|x] wrt ltotexp evaluated at xbar

*HOW MANY CLASSES?
quietly fmm 2, vce(robust): regress lmedexp $xlist
estat ic
quietly fmm 3, vce(robust): regress lmedexp $xlist
estat ic
quietly fmm 4, vce(robust): regress lmedexp $xlist
estat ic
*Here we compare using AIC and BIC. We can select the number of classes with
*smallest AIC/BIC.

