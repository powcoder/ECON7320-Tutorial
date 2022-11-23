**ECON6300- Practical-Week 2- Earnings decomposition

cd "Your directory here"

********** SETUP *******
***

set more off

version 13
clear all
set linesize 82
set scheme s1mono  /* Graphics scheme */

********** DATA DESCRIPTION **********
* File e6300_Prac_01_mabel-earndecomp.dta is extract from 
* MABEL waves 1-3 
* Data pertain to annual earnings of GPs
* A small selection of variables is used for illustration

********** DATA SUMMARY STATISTICS

use ECON6300_Prac_01_mabelearndecomp.dta
global xlist1 yhrs expr exprsq fellow pgradoth pracsize childu5 visa

describe

summarize

sum if female==0,detail

sum if female==1,detail

*DETERMINE AN APPROPRIATE DEPEDENT VARIABLE

sum yearn, detail

boxcox yearn $xlist1, nolog

gen logyearn=log(yearn)

*REGRESSION AND SPECIFICATION TESTS

reg logyearn $xlist1, vce(robust)
rvfplot

quietly reg logyearn $xlist1
predict dfits, dfits
scalar threshold = 2*sqrt((e(df_m)+1)/e(N))
display "dfits threshold = "  %6.3f threshold
tabstat dfits, stat (min p1 p5 p95 p99 max) format(%9.3f) col(stat)
list dfits yearn logyearn if abs(dfits) > 2*threshold & e(sample), clean

quietly regress logyearn $xlist1, vce(robust)
estat ovtest
linktest

quietly regress logyearn $xlist1
estat hettest, iid
estat hettest $xlist1, iid

*REGRESSION FOR MALES AND FEMALES

regress logyearn $xlist1 if female==0, vce(robust)
regress logyearn $xlist1 if female==1, vce(robust)

*HETEROGENEOUS COEFFICIENTS FOR MALES AND FEMALES

gen yhrs_fem=yhrs*female
gen expr_fem=expr*female
gen exprsq_fem=exprsq*female
gen fellow_fem=fellow*female
gen pgradoth_fem=pgradoth*female
gen pracsize_fem=pracsize*female 
gen childu5_fem= childu5*female
gen visa_fem=childu5*female

regress logyearn $xlist1 female *_fem, vce(robust)
test female yhrs_fem expr_fem exprsq_fem fellow_fem pgradoth_fem pracsize_fem childu5_fem visa_fem

*OAXACA-BLINDER DECOMPOSITION

oaxaca logyearn $xlist1,  by (female) detail vce(robust)


 
