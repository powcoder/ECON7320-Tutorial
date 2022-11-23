clear
cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2018\T3"

*data are table F17.2 here: http://pages.stern.nyu.edu/~wgreene/Text/Edition7/tablelist8new.htm
insheet using redbook.csv

* generate dependent variable

gen y=yrb>0

* number of children is top coded. replace 5.5 with 6 so that we can use i.v4 in
* our analysis

replace v4=6 if v4==5.5

* generate categories for categorial variables

tab v1, gen(V1)
tab v4, gen(V4)
tab v5, gen(V5)
tab v6, gen(V6)
tab v7, gen(V7)
tab v8, gen(V8)

* covariate list

global xlist V11-V14 v2 v3 V41-V45 V51-V53 V61-V65 V71-V75 V81-V85

* probit, change in years married, predict probability, classification table, marginal effects at mean and mean
* marginal effects
probit yrb $xlist
prchange v2
predict pprobit, pr
estat classification
margins, dydx(*) atmean
margins, dydx(*)


*logit, change in years married, predict probability, classification table, marginal effects at mean and mean
* marginal effects
logit yrb $xlist
prchange v2
predict plogit, pr
estat classification
margins, dydx(*) atmean
margins, dydx(*)

*summarise fitted probabilities for whole sample, those having an affair and those not
summarize plogit pprobit
summarize plogit pprobit if y==1
summarize plogit pprobit if y==0


