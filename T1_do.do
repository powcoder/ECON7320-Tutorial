clear

*SET DIRECTORY, LOAD DATA AND LOOK AT DATA
cd "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2019\T1"

use consumption.dta

browse

*SCATTER PLOT
scatter INC CONS

*CHANGE DATA, GENERATE NEW VARIABLES, RENAME, KEEP AND DROP
replace INC=100 in 5
replace INC=. in 5

gen INCCONS=INC*CONS

rename INCCONS inccons

drop inccons

keep INC CONS

drop in 10

drop in 8/9

*SUMMARISE, TABULATE, CORRELATE, TEST SAMPLE MEAN AND REGRESSION

sum

sum INC CONS

tab INC

corr INC CONS

ttest INC=100

regress INC CONS, robust

*GENERATE AND USE GROUP VARIABLES

gen GRP=1

replace GRP=2 in 1/5

tab GRP, gen(G)

bysort GRP: sum INC CONS

regress INC CONS G2, robust
regress INC CONS i.GRP, robust

*GENERATE DUMMY VARIABLE AND TEST MEAN
gen D=INC>=100

ttest D=0.5

*HELP!
help sum

*PAGE UP

*IMPORT
clear
import delimited "C:\Users\uqcrose3\Google Drive\Teaching UQ\ECON6300\ECON6300-2019\T1\fultonfish.dat", delimiter(space, collapse) clear

