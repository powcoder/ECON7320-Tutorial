*ECON6300-2016- W7- Practical - Bayesian Regression
* File needed for second part: psidextract1year.dta


* i.i.d. example
* Generate a sample of 50 observations on y. We treat the mean as known and variance as unknown.
clear all
quietly set obs 50
set seed 10101
gen y = rnormal(10,10)
sum

cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T9"

* Bayesian analysis
* The MLE is the sample mean
mean y

* Bayesian posterior for mu with y~N(mu,sigma^2=100) and N(5,4) prior for mu
set seed 10101
bayesmh y, likelihood(normal(100)) prior({y:}, normal(5,4)}) ///
saving(bayestemp_iid, replace)
*Note that the posterior mean is between the prior mean 5 and the true mean 10.
*The acceptance rate is fine (should not be too close to zero or one)
*Efficiency measures the strength of autocorrelation in the chain (low efficiency=high autocorrelation).
*The MCSE (interpret like a standard error) measures the simulation error in estimating the posterior mean
*The credible interval gives the 2.5 and 97.5 percentiles of the posterior distribution.

* Bayesian inference
* Bayesian hypothesis test: Pr[mu > 10]
bayestest interval {y:_cons}, lower(10) upper(.)
*Estimated Pr[mu>10] is 0.1423

* Bayesian statistics for transformation of parameter mu
bayesstats summary ({y:_cons}^2)

* Bayesian diagnostics 
* Diagnostic plots for MH posterior draws
bayesgraph diagnostics {y:_cons}, scale(1.1)
* Allows us to see whether the MCMC worked well. We get the series of
* mu(s) (top left), a histogram, an autocorrelation plot and the density of the first and second
* half of the MCMC process. If it has worked well, the autocorrelation at order 2+ should
* be close to zero and the density for the first and second half should be similar.

* Sensitivity analysis
* Compare posterior for 5 different starting values
set seed 10101
  forvalues i=1/5 {
  local start = rnormal(10,3^2)
  quietly bayesmh y, likelihood(normal(100)) prior({y:}, normal(5,4)) ///
   initial({y:_cons} `start')
  matrix pstart = (nullmat(pstart) \ `start')
  matrix pmeans = (nullmat(pmeans) \ e(mean))
  matrix psds = (nullmat(psds) \ e(sd))
  }
  matrix p_all = pstart,pmeans,psds
  matrix list p_all, title("Start value, post. means and st. devs. for 5 runs")
*If the MCMC worked well, the starting value shouldn't matter. Here it matters a little!

* Compare posterior for 2 different priors
  capture matrix drop pmeans
  capture matrix drop psds
  capture matrix drop p_all
  quietly bayesmh y, likelihood(normal(100)) prior({y:}, normal(5,4)) ///
 seed(10101)
  matrix pmeans = e(mean)
  matrix psds = e(sd)
  quietly bayesmh y, likelihood(normal(100)) prior({y:}, normal(5,40)) ///
 seed(10101)
  matrix pmeans = pmeans \ e(mean)
  matrix psds = psds \ e(sd)
  matrix p_all = pmeans,psds
  matrix list p_all, title("Post. means and st. devs. for 2 different priors")
* Our prior makes quite a big difference! The flatter is is, the closer the posterior mean
* to the MLE estimator (which is the sample mean)
 
* Summarize the unique retained draws
  use bayestemp_iid.dta, clear
  sum

* Expand to get the 10,000 MH draws including repeated draws
 expand _frequency
 sort _index
 gen s = _n
 sum eq1_p1
 
 *Display the posterior density
 hist eq1_p1

* Graph the first 50 draws of mu
 quietly tsset s
 tsline eq1_p1 if s < 50, scale(1.5) ytitle("Parameter mu") ///
 xtitle("MCMC posterior draw number") saving(graph1, replace)

* Bayesian regression analysis using psidextract1year.dta
* Read in earnings - schooling data
 use psidextract1year.dta, clear
 describe lwage ed exp exp2

 keep if _n <= 100
 summarize  lwage ed exp exp2

 * MLE for the regression
 regress  lwage ed exp exp2

 * Bayesian posterior with informative priors: normal for b, inv gamma for s2
 set seed 10101
 bayesmh lwage ed exp exp2, likelihood(normal({var})) ///
 prior({lwage:ed}, normal(0.06,0.0001)) ///
 prior({ lwage:exp}, normal(0.02,0.0001)) ///
 prior({ lwage:exp2}, normal(0.002,0.001)) ///
 prior({ lwage:_cons},normal(10,100)) ///
 prior({var},igamma(1,0.5)) saving(bayestemp_fullregress, replace) burnin(5000) mcmcsize(10000)

  * Diagnostic plots for MH posterior draws of beta_ed
  bayesgraph diagnostics { lwage:ed}

  * Trace plot for all five parameters
  bayesgraph trace _all, combine
 
 * MH with blocking: var in separate block
 quietly bayesmh  lwage ed exp, likelihood(normal({var})) ///
 prior({ lwage:ed}, normal(0.06,0.0001)) ///
 prior({ lwage:exp}, normal(0.02,0.0001)) ///
 prior({ lwage:exp2}, normal(0.002,0.001)) ///
 prior({ lwage:_cons},normal(10,100)) ///
 prior({var},igamma(1,0.5)) block({var}) seed(10101)
 bayesstats summary

 * Hybrid MH with Gibbs sampling subcomponent
 quietly bayesmh  lwage ed exp, likelihood(normal({var})) ///
 prior({ lwage:ed}, normal(0.06,0.0001)) ///
 prior({ lwage:exp}, normal(0.02,0.0001)) ///
 prior({ lwage:exp2}, normal(0.002,0.001)) ///
 prior({ lwage:_cons},normal(10,100)) ///
 prior({var},igamma(1,0.5)) block({var}, gibbs) seed(10101)
 quietly bayesstats summary
 display "Overall acceptance rate = " e(arate)

