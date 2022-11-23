********** GENERATE DATA  **********
clear all
* Graphs will be for z = -2.5 to 2.5 in increments of 0.02
set obs 251
gen z = -2.52 + 0.02*_n
sum
********** CALCULATE THE KERNELS **********

* Indicator for |z| < 1
gen abszltone = 1
replace abszltone = 0 if abs(z)>=1

gen kuniform = 0.5*abszltone

gen ktriangular = (1 - abs(z))*abszltone

* Stata calls the usual Epanechnikov kernel epan2
gen kepanechnikov = (3/4)*(1 - z^2)*abszltone

* Stata uses alternative epanechnikov
gen abszltsqrtfive = 1
replace abszltsqrtfive = 0 if abs(z)>=sqrt(5)
gen kepanstata = (3/4)*(1 - (z^2)/5)/sqrt(5)*abszltsqrtfive

gen kquartic = (15/16)*((1 - z^2)^2)*abszltone

gen ktriweight = (35/32)*((1 - z^2)^3)*abszltone

gen ktricubic = (70/81)*((1 - (abs(z))^3)^3)*abszltone

gen kgaussian = normalden(z)

gen k4thordergauss = (1/2)*(3-(z^2))*normalden(z)

gen k4thorderquartic = (15/32)*(3 - 10*z^2 + 7*z^4)*abszltone

sum

********** PLOT THE KERNEL FUNCTIONS **********

* Epanstata is similar to Gaussian kernel. Less peaked than Epanechnikov
graph twoway (line kuniform z) (line kepanechnikov z) (line kepanstata z) /*
    */ (line kgaussian z), title("Four standard kernel functions")

* Triangular, Quartic, Triweight and Tricubic are similar 
* and are more peaked than Epanechnikov
graph twoway (line ktriangular z) (line kquartic z) (line ktriweight z) /*
    */ (line ktricubic z), title("Four similar kernel functions")

graph twoway (line k4thordergauss z) (line k4thorderquartic z), /*
    */ title("Two fourth order kernel functions")

*****************************************************************************
***************** PART 2 ****************************************************

clear all

cd "C:\Users\uqcrose3\Desktop\New folder"

 * Nonparametric density estimation and nonparametric regression using actual data.

* (1) Histogram: Like Figure 9.1 in chapter 9.2.1 (ch9hist) in MMA
* (2) Kernel Like density estimate as bandwidth varies: Figure 9.2 in chapter 9.2.1 (ch9kd1)
* (3) Kernel density estimate as kernel varies: Like Figure 9.4 in chapter 9.3.4 (ch9kdensu1)
* (4) Lowess regression: Like Figure 9.3 in chapter 9.4.3 (ch9ksm1)
* (5) Extra: Nearest neighbours regression: using Lowess and using add-on knnreg
* (6) Extra: Kernel regression: using add-on kernreg

* Using data on earnings and hours of GPs (see below) from Wave 1 of MABEL 

* NOTE: This particular program uses version 8.2 rather than 8.0
*       For kernel density Stata uses an alternative formulation of Epanechnikov
*       To follow book and e.g. Hardle (1990) use epan2 rather than epan 
*       epan = epan2 if epan bandwidth is epan2 bandwidth divided by sqrt(5) 
*       where kernel epan2 is an update to Stata version 8.2

* To do (5) and (6) you need Stata add-ons knnreg and kernreg
* In Stata give command  search knnreg  and  search kernreg

  
********** SETUP

set more off
version 13
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION
*
* The original data are from the MABEL Wave 1 data
* From University of Melbourne's ISER   
* 2940 observations on 5 variables for GPs in the cohort of year 2008 

* yearn:            Gross annual earnings
* yhrs :            Annual hours worked
* female:           Female
* lnyearn:          log of annual earnings
* lnyhrs :          log of annual hours

 ********** READ DATA ********** 
use e6300-NP1.dta 

********* ANALYSIS: (1)-(3) NONPARAMETRIC DENSITY ESTIMATES 

set scheme s1mono

* Here give bin width for histogram and kdensity  

* Calculate Silberman's plugin estimate of optimal bandwidth 
* with delta given in Table 9.1 for Epanechnikov kernel and using (9.13) in MMA
* h=1.3643*delta*N^(-0.2)*min(sd,iqr/1.349)
* Different kernels have different deltas (see Table 9.1 in MMA).
quietly sum lnyearn, detail
global sadj = min(r(sd),(r(p75)-r(p25))/1.349)
di "sadj: " $sadj " iqr/1349: " (r(p75)-r(p25))/1.349 " stdev: " r(sd)
global bwepan2 = 1.3643*1.7188*$sadj/(r(N)^0.2)
di "Bandwidth: " $bwepan2 

* HISTOGRAM ONLY - 
graph twoway (histogram lnyearn, bin(20) bcolor(*.2)), /*
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Histogram for Log Earnings") /*
  */ xtitle("Log Annual Earnings", size(medlarge)) xscale(titlegap(*5)) /*
  */ ytitle("Density", size(medlarge)) yscale(titlegap(*5)) /*
  */ legend(pos(10) ring(0) col(1)) legend(size(small)) /*
  */ legend( label(1 "Histogram")) 
graph save logearnings, replace
graph export lnyearnhist.eps, replace

* COMBINED HISTOGRAM AND KERNEL DENSITY ESTIMATE
graph twoway (histogram lnyearn, bin(20) bcolor(*.2)) /*
  */ (kdensity lnyearn, bwidth($bwepan2) epan2 clstyle(p1)), /* 
  */ title("Histogram and Kernel Density for Log Earnings") /*
  */ caption("Note: Kernel is Epanechnikov with bandwidth 0.31") 

* KERNEL DENSITY ESTIMATE FOR 3 BANDWIDTHS
global bwonehalf = 0.5*$bwepan2
global btwotimes = 2*$bwepan2
graph twoway (kdensity lnyearn, bwidth($bwonehalf) epan2 clstyle(p2)) /*
  */  (kdensity lnyearn, bwidth($bwepan2) epan2 clstyle(p1)) /*
  */  (kdensity lnyearn, bwidth($btwotimes) epan2 clstyle(p3)), /*
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Density Estimates as Bandwidth Varies") /*
  */ xtitle("Log Annual Earnings", size(medlarge)) xscale(titlegap(*5)) /* 
  */ ytitle("Kernel density estimates", size(medlarge)) yscale(titlegap(*5)) /* 
  */ legend(pos(11) ring(0) col(1)) legend(size(small)) /*
  */ legend( label(1 "One-half plug-in") label(2 "Plug-in") /*
  */         label(3 "Two times plug-in"))  
graph save lnyearnings-bw, replace
graph export lnyearnings-bw.eps, replace
*It is a good idea to try half and double Silberman's bandwidth too.

* KERNEL DENSITY ESTIMATE FOR 4 DIFFERENT KERNELS - Figure 9.4
* Calculate Silberman's plugin optimal bandwidths using (9.13)
* with delta given in Table 9.1 for the different kernels
* Use sadj calculated earlier for Epanecnnikov
global bwgauss = 1.3643*0.7764*$sadj/(_N^0.2)
global bwbiweight = 1.3643*2.0362*$sadj/(_N^0.2)
global bwrectang = 0.5*1.3643*1.3510*$sadj/(_N^0.2)
di "Usual Epanechnikov (epan2):      " $bwepan2 
di "Gaussian:                        " $bwgauss 
di "Quartic or biweight:             " $bwbiweight
di "Uniform or rectangular:          " $bwrectang
graph twoway (kdensity lnyearn, width($bwepan2) epan2) /*
  */ (kdensity lnyearn, width($bwgauss) gauss) /*
  */ (kdensity lnyearn, width($bwbiweight) biweight) /* 
  */ (kdensity lnyearn, width($bwrectang) rectangle), /*
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Density Estimates as Kernel Varies") /*
  */ xtitle("Log annual earnings", size(medlarge)) xscale(titlegap(*5)) /* 
  */ ytitle("Kernel density estimates", size(medlarge)) yscale(titlegap(*5)) /* 
  */ legend(pos(11) ring(0) col(1)) legend(size(small)) /*
  */ legend( label(1 "Epanechnikov (h=0.545)") label(2 "Gaussian (h=0.246)") /*
  */         label(3 "Quartic (h=0.646)") label(4 "Uniform (h=0.214)"))
graph save kdensu1, replace
graph export kdensu1.eps, replace
*Provided that the optimal bandwidth is used, the choice of kernel is not important.

* SHOW THAT STATA EPANECHNIKOV = USUAL EPANECHNIKOV
* Once divide usual Epanechnikov bandwidth by sqrt(5). 
global bwepan = $bwepan2/sqrt(5)
graph twoway (kdensity lnyearn, width($bwepan2) epan2) /*
   */  (kdensity lnyearn, width($bwepan) epan), /*
   */  title("Epan = Epan2 if bandwidth adjusted") /*
   */  legend( label(1 "Usual Epanechnikov") label(2 "Stata Epanechnikov"))   


********* ANALYSIS: (4) LOWESS NONPARAMETRIC REGRESSION ESTIMATES

* LOWESS WITH DEFAULT BANDWIDTH of 0.8 
lowess lnyearn lnyhrs
*Takes 0.8*N nearest observations (those with smallest |x_i-x|) and 
* computes the mean of y for those 0.8*N observations.

* LOWESS REGRESSION WITH BANDWIDTHS of 0.1, 0.4 and 0.8 - Figure 9.3
graph twoway (scatter lnyearn lnyhrs, msize(medsmall) msymbol(o)) /*
  */ (lowess lnyearn lnyhrs, bwidth(0.8) clstyle(p2)) /*
  */ (lowess lnyearn lnyhrs, bwidth(0.4) clstyle(p1)) /* 
  */ (lowess lnyearn lnyhrs, bwidth(0.1) clstyle(p3)), /*  
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Nonparametric Regression as Bandwidth Varies") /*
  */ xtitle("Years of Hours worked", size(medlarge)) xscale(titlegap(*5)) /* 
  */ ytitle("Log Annual Earnings", size(medlarge)) yscale(titlegap(*5)) /*
  */ legend(pos(7) ring(0) col(2)) legend(size(small)) /*
  */ legend( label(1 "Actual data") label(2 "Bandwidth h=0.8") /*
  */         label(3 "Bandwidth h=0.4") label(4 "Bandwidth h=0.1"))
graph save ksm1, replace
graph export ksm1.eps, replace

********* ANALYSIS: (5) EXTRA: K-NEAREST NEIGHBORS NONPARAMETRIC REGRESSION

* NEAREST NEIGHBOURS REGRESSION USING LOWESS
* Use lowess with mean and noweight options to give running means = centered kNN
global knnbwidth = 0.3
di "knn via Lowess uses following % of sample: " $knnbwidth
lowess lnyearn lnyhrs, bwidth($knnbwidth) mean noweight

* LOWESS COMPARED TO NEAREST NEIGHBOURS
graph twoway (lowess lnyearn lnyhrs, bwidth(0.3) mean noweight) /*
  */ (lowess lnyearn lnyhrs, bwidth(0.3)), /*
  */ title("Centered kNN versus Lowess") /*
  */ legend( label(1 "Centered kNN") label(2 "Lowess 0.3"))

* NEAREST NEIGHBOURS REGRESSION USING KNNREG COMPARED TO USING LOWESS
* knnreg is a Stata add-on (in Stata search knnreg to find and download)
* Here we verify that same as lowess knn except knnreg drops endpoints
global k = round($knnbwidth*_N)
di "knnreg uses following number of neighbours: " $k
knnreg lnyearn lnyhrs, k($k) gen(knnregpred) ylabel nograph
lowess lnyearn lnyhrs, bwidth($knnbwidth) gen(knnlowesspred) mean noweight nograph
* Following shows that the same except knnreg drops endpoints and lowess does not
sum knnlowesspred knnregpred
corr knnlowesspred knnregpred

******** ANALYSIS: (5) Comparison with parametric specifications

gen lnyhrs2=lnyhrs^2
gen lnyhrs3=lnyhrs^3
quietly reg lnyearn lnyhrs*
predict lnyearnhat

sort lnyhrs

graph twoway (scatter lnyearn lnyhrs, msize(medsmall) msymbol(o)) /*
  */ (lowess lnyearn lnyhrs, clstyle(p1)) /* 
  */ (line lnyearnhat lnyhrs, clstyle(p1)) (lfit lnyearn lnyhrs, clstyle(p2)), /*
  */ scale (1.2) plotregion(style(none)) /*
  */ title("Lowess vs parametric") /*
  */ xtitle("Log hours", size(medlarge)) xscale(titlegap(*5)) /* 
  */ ytitle("Log earnings", size(medlarge)) yscale(titlegap(*5)) /*
  */ legend(ring(0) col(1)) legend(size(small)) /*
  */ legend( label(1 "Actual Data") label(2 "Lowess") /*
  */         label(3 "OLS Linear Regression") label(3 "OLS Cubic Regression") )
