*modified from mus14p1bin.do  March 2014 for Stata version 13
clear
cd "Your directory"

drop _all 
cap log close

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
  
* 14.4 EXAMPLE
* 14.5 HYPOTHESIS AND SPECIFICATION TESTS
* 14.6 GOODNESS OF FIT AND PREDICTION
* 14.7 MARGINAL EFFECTS 
* 14.8 ENDOGENOUS REGRESSORS

* To run this program you need data file 
*   mus14data.dta 
* in your directory
* No Stata user-written commands are used

* Dataset comes from HRS 2000

********** SETUP

set more off
version 11
clear all
set scheme s1mono  /* Graphics scheme */
  
********** 14.3 DATA DESCRIPTION

* Dataset comes from HRS 2000
 
*********** 14.4 EXAMPLE

clear
* Load data
use mus14.dta
* Describe data
desc
* Summary statistics of variables
global xlist age hstatusg hhincome educyear married hisp
generate linc = ln(hhinc)
global extralist linc female white chronic adl sretire
summarize ins retire $xlist $extralist

* 14.4.2 Logit regression

* Logit regression
logit ins retire $xlist
 
* Estimation of several models
quietly logit ins retire $xlist
estimates store blogit
quietly probit ins retire $xlist 
estimates store bprobit
quietly regress ins retire $xlist 
estimates store bols
quietly logit ins retire $xlist, vce(robust)
estimates store blogitr
quietly probit ins retire $xlist, vce(robust)
estimates store bprobitr
quietly regress ins retire $xlist, vce(robust)
estimates store bolsr

* Table for comparing models 
estimates table blogit blogitr bprobit bprobitr bols bolsr, /*
   */ t stats(N ll) b(%7.3f) stfmt(%8.2f)
   
* Rules of thumb for the scaling of probit, logit and ols parameters are appropriate

* It is not important to use vce(robust) for logit and probit. This is because
* the variance is restricted such that Var(y|x)=F(x*beta)(1-F(x*beta)) so we have heteroskedasticity
* of a known form. It is important to use vce(robust) for OLS, as this restriction is not
* imposed and we know that there is heteroskedasticity.

* Signs of parameters are the signs of the marginal effects. Scale is hard to interpret.
* For the logistic, we can use the log odds ratio interpretation

********** 14.5 HYPOTHESIS AND SPECIFICATION TESTS

* Wald test for zero interactions
generate age2 = age*age
generate agefem = age*female
generate agechr = age*chronic
generate agewhi = age*white
global intlist age2 agefem agechr agewhi
quietly logit ins retire $xlist $intlist
test $intlist 

* Do not reject the null that the interactions are jointly equal to zero (Wald)
* The Wald test ascertains whether the distance between the coefficients and 0 is statistically large

* Likelihood-ratio test
quietly logit ins retire $xlist $intlist
estimates store B 
quietly logit ins retire $xlist
lrtest B 

* Do not reject the null that the interactions are jointly equal to zero (LR)
* The likelihood ratio test compare the likelihoods of the models with and without interactions
* and tests whether the difference is statistically large

**FIGURE 1: PLOT PREDICTED PROBABILITY AGAINST hhincome FOR MODELS

* Calculate and summarize fitted probabilities
quietly logit ins hhincome
predict plogit, pr
quietly probit ins hhincome  
predict pprobit, pr
quietly regress ins hhincome
predict pols, xb
summarize ins plogit pprobit pols

* Logit and OLS are such that the mean predicted probability is equal to the sample frequency
* Probit is not.

* Following gives Figure mus14fig1.eps
sort hhincome
graph twoway (scatter ins hhincome, msize(vsmall) jitter(3)) /*
  */ (line plogit hhincome, clstyle(p1)) /*
  */ (line pprobit hhincome, clstyle(p2)) /*
  */ (line pols hhincome, clstyle(p3)), /*
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Predicted Probabilities Across Models") /*
  */ xtitle("HHINCOME (hhincome)", size(medlarge)) xscale(titlegap(*5)) /* 
  */ ytitle("Predicted probability", size(medlarge)) yscale(titlegap(*5)) /*
  */ legend(pos(1) ring(0) col(1)) legend(size(small)) /*
  */ legend(label(1 "Actual Data (jittered)") label(2 "Logit") /*
  */         label(3 "Probit") label(4 "OLS"))
graph export mus14fig1.eps, replace

* We compare the predicted probabilities and how they change as income changes
* OLS goes below 0 and beyond 1!

* Fitted probabilities for selected baseline x ( fit of P(y=1|X=x) )
* You may need to install spostado using the command findit spostado
quietly logit ins retire $xlist
prvalue, x(age=65 retire=0 hstatusg=1 hhincome=50 educyear=17 married=1 hisp=0)

* Comparing fitted probability and dichotomous outcome
quietly logit ins retire $xlist
estat classification

* Produces the classification table based on yhat=1 if F(x*beta hat)>0.5
* D is y=1, ~D=y=0, + is yhat=1, - is yhat=0

********** 14.7 MARGINAL EFFECTS 

* Marginal effects (MER) after logit
quietly logit ins i.retire age i.hstatusg hhincome educyear i.married i.hisp
margins, dydx(*) at (retire=1 age=75 hstatusg=1 hhincome=35 educyear=12   ///
 married=1 hisp=1) noatlegend   // (MER)
 
* Marginal effects at a point x: d Prob(y=1|X=x)/dX

* Marginal effects (MEM) after logit
quietly logit ins i.retire age i.hstatusg hhincome educyear i.married i.hisp
margins, dydx(*) atmean noatlegend  // (MEM)

* Marginal effects at the mean of x: d Prob(y=1|X=xbar)/dX

* Marginal effects (AME) after logit
quietly logit ins i.retire age i.hstatusg hhincome educyear i.married i.hisp
margins, dydx(*) noatlegend        // (AME)
* Average marginal effect: (1/N) sum_i d Prob(y=1|X=x_i)/dX

* Computing change in probability after logit 
quietly logit ins retire $xlist 
prchange hhincome

* Change in probability for a change in x from various starting points

********** CLOSE OUTPUT **********
