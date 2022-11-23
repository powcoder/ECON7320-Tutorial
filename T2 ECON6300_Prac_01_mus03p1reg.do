* mus03p1reg.do   
cap log close

********** OVERVIEW OF mus03p1reg.do **********

* Stata program 
* copyright C 2010 by A. Colin Cameron and Pravin K. Trivedi 
* used for "Microeconometrics Using Stata, Revised Edition" 
* by A. Colin Cameron and Pravin K. Trivedi (2010)
* Stata Press

* Chapter 3
* 3.2: DATA: SUMMARY STATISTICS
* 3.4: BASIC REGRESSION ANALYSIS
* 3.5: SPECIFICATION ANALYSIS
* 3.6: PREDICTION
* 3.7: SAMPLING WEIGHTS
* 3.8: OLS USING MATA

* To run you need files
*   mus03data.dta 
* in your directory
* Stata user-written commands esttab and estadd are used

********** SETUP **********

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2019\T2"

set more off
version 11
clear all
set linesize 82
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION **********

* File mus03data is extract from MEPS

************ 3.2: DATA SUMMARY STATISTICS

* Variable description for medical expenditure dataset
use ECON6300_Prac_01_mus03data.dta
describe totexp ltotexp posexp suppins phylim actlim totchr age female income

* Summary statistics for medical expenditure dataset
summarize totexp ltotexp posexp suppins phylim actlim totchr age female income

* 96% incur some out-of-pocket medical expense
* 58% have private insurance
* 58% are female. Why?!
* Missing data for ltotexp. Why?!
* Do variables have the expected range? Income?

* Tabulate variable
tabulate income if income <= 0

* How prevalent is negative income? 
* Is it feasible? 
* Should we drop these from the sample?

* Detailed summary statistics of a single variable
summarize totexp, detail

* Important to summarise the dependent variable
* Very large variation
* Highly skewed (median<<mean), skewness = 4.16 (0 for symmetric data)
* Large kurtosis: Fat tails (standard normal = 3)
* Typical of economic data: Income, wages, house prices,...
* Suggests a model with multiplicative errors
* Or, we can do a transformation such as log(totexp)
* We lose 109 observations with totexp=0
* A better approach would use a two-part selection model such as in Chapter 16

* Detailed summary statistics of a single variable
summarize ltotexp, detail

* Skewness and kurtosis are much reduced

* Two-way table of frequencies
table female totchr

* Two-way table with row and column percentages and Pearson chi-squared
tabulate female suppins, row col chi2

* Women more likely to have insurance than not (55.24)
* Men more likely than women to have insurance (62.11>55.24)
* Pearson's chi-squared: Rejects H0: Independence of gender and insurance

* Three-way table of frequencies
table female totchr suppins

* One-way table of summary statistics
table female, contents(N totchr mean totchr sd totchr p50 totchr)

* Set contents of table
* Women have more chronic conditions on average (1.82>1.66)

* Two-way table of summary statistics
table female suppins, contents(N totchr mean totchr)

* Those with insurance have more chronic problems on average
* Especially true for men

* Summary statistics obtained using command tabstat
tabstat totexp ltotexp, stat (count mean p50 sd skew kurt) col(stat)

* Tables of specific summary statistics

* Kernel density plots with adjustment for highly skewed data
kdensity totexp if posexp==1, generate (kx1 kd1) n(500) 

*Estimate and plot the density of totexp, and save the x and y values

graph twoway (line kd1 kx1) if kx1 < 40000, name(levels)

* Restrict expenditure to [0,40000]
* Why not use  kdensity totexp if posexp==1&totexp<40000?!

kdensity ltotexp if posexp==1, generate (kx2 kd2) n(500) 
graph twoway (line kd2 kx2) if kx2 < ln(40000), name(logs)

graph combine levels logs, iscale(1.0)
graph export mus03fig1.eps, replace

* Combine the plots for levels and logs
* Export an .eps file (best format for use in LATEX)

*********** 3.4: BASIC REGRESSION ANALYSIS

* Pairwise correlations for dependent variable and regressor variables
correlate ltotexp suppins phylim actlim totchr age female income

* Largest correlation of log expenditure with health variables phylim, actlim, totchr
* Regressors weakly correlated apart from health variables

* OLS regression with heteroskedasticity-robust standard errors
regress ltotexp suppins phylim actlim totchr age female income, vce(robust)

* Joint significance of regressors. (p(F)=0.0000)
* Explain fraction 0.23 of the variance of ltotexp
* All regressors individually signifcant at the 5% size apart from age and female
* Age not significant because we control for health status
* Private insurance is associated with a ~26% increase in health expenditure holding all else constant
* Women spend ~8.4% less than men holding all else constant
* Income has a small coefficient, but a standard deviation increase in income (22) increases expenditure by ~22*0.0025=5.5%
* These computations of the effect size are approximations!

* Display stored results and list available postestimation commands
ereturn list
help regress postestimation

* Wald test of equality of coefficients
quietly regress ltotexp suppins phylim actlim totchr age female ///
  income, vce(robust)
test phylim = actlim

* H0: Functional limitations and Activity limitations have the same effect
* Fail to reject at 0.05 level

*  Joint test of statistical significance of several variables
test phylim actlim totchr

* H0: Health condition does not affect expenditure
* Reject at 0.05 level

* Store and then tabulate results from multiple regressions
quietly regress ltotexp suppins phylim actlim totchr age female income, vce(robust)
estimates store REG1
quietly regress ltotexp suppins phylim actlim totchr age female educyr, vce(robust)
estimates store REG2
estimates table REG1 REG2, b(%9.4f) se stats(N r2 F ll) keep(suppins income educyr)

* Tabulate results using user-written command esttab to produce cleaner output
esttab REG1 REG2, b(%10.4f) se scalars(N r2 F ll) mtitles ///
  keep(suppins income educyr) title("Model comparison of REG1-REG2")
  
* Compare original model with one that replaces income with years of education

* Write tabulated results to a file in latex table format
quietly esttab REG1 REG2 using mus03table.tex, replace b(%10.4f) se scalars(N r2 F ll) ///
   mtitles keep(suppins age income educyr _cons) title("Model comparison of REG1-REG2")

* Add a user-calculated statistic to the table
estimates drop REG1 REG2

* Remove stored results from memory

quietly regress ltotexp suppins phylim actlim totchr age female ///
  income, vce(robust)
estadd scalar pvalue = Ftail(e(df_r),e(df_m),e(F))

* Redo regression and compute p-value of F-test

estimates store REG1

* Store estimates

quietly regress ltotexp suppins phylim actlim totchr age female ///
  educyr, vce(robust)
estadd scalar pvalue = Ftail(e(df_r),e(df_m),e(F))
estimates store REG2

* Do the same for the second specification

esttab REG1 REG2, b(%10.4f) se scalars(F pvalue) mtitles keep(suppins) 

* Factor variables for sets of indicator variables and interactions
regress ltotexp suppins phylim actlim totchr age female c.income ///
 i.famsze c.income#i.famsze, vce(robust) noheader allbaselevels
 
 * Add factor variable for family size and interact with income
 * Family size of 1 is the comparison category

* Test joint significance of sets of indicator variables and interactions
testparm i.famsz c.income#i.famsze

* Do not reject joint significance of these variables

* Compute the average marginal effect in model with interactions
quietly regress totexp suppins phylim actlim totchr age female c.income ///
 i.famsze c.income#i.famsze, vce(robust) noheader allbaselevels
margins, dydx(income)

* Compute the average of d totexp/d income

* Compute elasticity for a specified regressor
quietly regress totexp suppins phylim actlim totchr age female income, vce(robust)
margins, eyex(totchr) atmean

* Compute the mean elasticity of the number of chronic conditions

********** 3.5: SPECIFICATION ANALYSIS

* Plot of residuals against fitted values
quietly regress ltotexp suppins phylim actlim totchr age female income, ///
  vce(robust)
rvfplot
graph export mus03fig2.eps, replace

* No extreme outliers but some with residual <-5

* Details on the outlier residuals
predict uhat, residual
predict yhat, xb
list totexp ltotexp yhat uhat if uhat < -5, clean

* These individuals all have very low total expenditure (<9$ per year)
* The model over-predicts for these individuals since there is little data in this region

* Compute dfits that combines outliers and leverage
quietly regress ltotexp suppins phylim actlim totchr age female income
predict dfits, dfits

* H=X(X'X)^(-1)X
* y_hat=X*beta_hat=H*y
* dsfits_i= H_ii
* If H_ii is large, y_i has a large effect on y_hat_i

scalar threshold = 2*sqrt((e(df_m)+1)/e(N))

* Rule of thumb: Worry about observations with |dfits_i|>2*sqrt(k/N)

display "dfits threshold = "  %6.3f threshold
tabstat dfits, stat (min p1 p5 p95 p99 max) format(%9.3f) col(stat)

* ~1-5% of sample a cause for concern

list dfits totexp ltotexp yhat uhat if abs(dfits) > 2*threshold & e(sample), clean

* Might want to worry about these 11 observations with dfits>4*sqrt(k/N)

* Boxcox model with lhs variable transformed
boxcox totexp suppins phylim actlim totchr age female income if totexp>0, nolog

* Fit the flexible non-linear model 
* (y_i^t-1)/t=x_i'*beta+u_i, u_i~N(0,sigma^2)
* t=1 yields y_i=x_i'*beta+u_i
* t=0 yields log(y)=x_i'*beta+u_i
* Reject log-linear and linear specifications! But theta_hat much closer to 0 than 1

* Variable augmentation test of conditional mean using estat ovtest
quietly regress ltotexp suppins phylim actlim totchr age female ///
  income, vce(robust)
estat ovtest

* Do we have the right predictors?
* Add powers of x_i'*beta_hat (4) and test their statistical significance
* We reject our original model

* Link test of functional form of conditional mean 
quietly regress ltotexp suppins phylim actlim totchr age female ///
  income, vce(robust)
linktest

* Linktest is simpler
* Regress y on y_hat and y_hat^2
* Reject original model if y_hat^2 is statistically signifcant

* Heteroskedasticity tests using estat hettest and option iid

* Test for heteroskedasticty of the form V(y|x)=h(a_1+z'a_2) where h(.) is a positive
* monotonic function such as exp(.)
* z is a function of x, usually x'*beta_hat or z=x
* We test H0: a_2=0

quietly regress ltotexp suppins phylim actlim totchr age female income
estat hettest, iid

* Breusch-Pagan test
* Relax u~iid normal to u~iid
* z=x'*beta_hat
* Reject H0

estat hettest suppins phylim actlim totchr age female income, iid

* z=x
* Reject H0
* Important to use robust standard errors!

* Information matrix test
quietly regress ltotexp suppins phylim actlim totchr age female income
estat imtest

* Omnibus test
* H0: y~N(x'*beta,I*sigma^2)
* Decomposed into H0: Homoskedasticity, symmetry, kurtosis =3
* Rejected

******* 3.6 PREDICTION

* Change dependent variable to level of positive medical expenditures
use  ECON6300_Prac_01_mus03data, clear
keep if totexp > 0   
regress totexp suppins phylim actlim totchr age female income, vce(robust)

* Prediction in model linear in levels
predict yhatlevels
summarize totexp yhatlevels

* Correct prediction at mean (by construction in models with intercepts)

* Compare median prediction and median actual value
tabstat totexp yhatlevels, stat (count p50) col(stat)

* Overpredict median due to right skewness of totexp

* Compute standard errors of prediction and forecast with default VCE
*quietly regress totexp suppins phylim actlim totchr age female income
*predict yhatstdp, stdp
*predict yhatstdf, stdf
*summarize yhatstdp yhatstdf
* How well does x'*beta_hat perform as an estimator of:
* 1) x'*beta (well)
* 2) y (poorly)

* Prediction in levels from a logarithmic model
quietly regress ltotexp suppins phylim actlim totchr age female income
quietly predict lyhat
generate yhatwrong = exp(lyhat)
generate yhatnormal = exp(lyhat)*exp(0.5*e(rmse)^2)
quietly predict uhat, residual
generate expuhat = exp(uhat)
quietly summarize expuhat
generate yhatduan = r(mean)*exp(lyhat) 
summarize totexp yhatwrong yhatnormal yhatduan yhatlevels 

* How to predict E[y|x] from E[log(y)|x]=x'*beta?
* Use exp(E[log(y)|x])?!
* How about E[y|x]=exp(x'*beta)*E[exp(u)]...
* For iid Normal u, use exp(x'*beta_hat)*exp(0.5*sigma_hat^2)
* For iid u, use exp(x'*beta_hat)*[N^(-1)*sum_i exp(u_hat_i)] (Duan(1983))

* exp(E[log(y)|x]) performs poorly (good as it is wrong)
* The log based predictions are close to the mean and only provide positive predictions
* The levels based prediction gives some negative predictions...

* Predicted effect of supplementary insurance: methods 1 and 2
bysort suppins: summarize totexp yhatlevels yhatduan

* Simulate the effect of a policy
* Compare predicted values based on the model in levels and logs
* Increase in expenditure of between 788 and 2129

* Predicted effect of supplementary insurance: method 3 for log-linear model
quietly regress ltotexp suppins phylim actlim totchr age female income
preserve
quietly replace suppins = 1
quietly predict lyhat1
generate yhatnormal1 = exp(lyhat1)*exp(0.5*e(rmse)^2) 
quietly replace suppins = 0
quietly predict lyhat0 
generate yhatnormal0 = exp(lyhat0)*exp(0.5*e(rmse)^2) 
generate treateffect = yhatnormal1 - yhatnormal0
summarize yhatnormal1 yhatnormal0 treateffect 
restore

* Alternatively, we predict expenditure if everybody is insured and not insured and look at the difference
* Average treatment effect is 2047.62

log close

******* 3.7 SAMPLING WEIGHTS (INDEPENDENT STUDY)

* Create artificial sampling weights
use mus03data.dta, clear
generate swght = totchr^2 + 0.5
summarize swght

* Calculate the weighted mean
mean totexp [pweight=swght]

* Perform weighted regression 
regress totexp suppins phylim actlim totchr age female income [pweight=swght]

* Weighted prediction
quietly predict yhatwols
mean yhatwols [pweight=swght], noheader  
mean yhatwols, noheader      // unweighted prediction

******** 3.8 OLS USING MATA

* OLS with White robust standard errors using Mata
use mus03data.dta, clear
keep if totexp > 0   // Analysis for positive medical expenditures only 
generate cons = 1
local y ltotexp
local xlist suppins phylim actlim totchr age female income cons

mata
  // Create y vector and X matrix from Stata dataset
  st_view(y=., ., "`y'")             // y is nx1
  st_view(X=., ., tokens("`xlist'")) // X is nxk
  XXinv = cholinv(cross(X,X))        // XXinv is inverse of X'X 
  b = XXinv*cross(X,y)               // b = [(X'X)^-1]*X'y
  e = y - X*b
  n = rows(X)
  k = cols(X)
  s2 = (e'e)/(n-k)
  vdef = s2*XXinv               // default VCE not used here
  vwhite = XXinv*((e:*X)'(e:*X)*n/(n-k))*XXinv  // robust VCE
  st_matrix("b",b')             // pass results from Mata to Stata
  st_matrix("V",vwhite)         // pass results from Mata to Stata
end

* Use Stata ereturn display to present nicely formatted results
matrix colnames b = `xlist'
matrix colnames V = `xlist'
matrix rownames V = `xlist'
ereturn post b V
ereturn display

// Not included in book
* Check
regress ltotexp suppins phylim actlim totchr age female income, ///
  vce(robust) noheader

********** CLOSE OUTPUT

