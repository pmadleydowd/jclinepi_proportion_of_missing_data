set more off
set logtype text
log using "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\log_expl_anls.txt", replace

********************************************************************************
* Author: Paul Madley-Dowd
* Date: 06 Nov 2017
* Description: MI empirical example exploratory analysis
********************************************************************************

********************************************************************************
* set up environment and read in data
*******************************************************************************
version 14

use "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\MI_emp_dat.dta", clear

********************************************************************************
* derive any additional variables
********************************************************************************
* IQ measures
rename cf813 	IQ_4_WPPSI
rename f8ws112 	IQ_8_WISC
rename ku503b 	IQ_9_CCC
rename fh6280 	IQ_15_WASI

gen nmIQ_4_WPPSI	= IQ_4_WPPSI	if IQ_4_WPPSI 	>0
gen nmIQ_8_WISC  	= IQ_8_WISC  	if IQ_8_WISC  	>0
gen nmIQ_9_CCC	 	= IQ_9_CCC		if IQ_9_CCC		>0
gen nmIQ_15_WASI	= IQ_15_WASI	if IQ_15_WASI	>0


* Auxiliary variables
gen tstscre=sh370/35 // 19 questions, 35 parts total
replace tstscre=. if sh370==-10

gen lrndif = se031a if se031a>0 
replace lrndif=0 if lrndif==2

gen mthstrm 	= 1 if se060 ==4
replace mthstrm = 2 if se060 ==3
replace mthstrm = 3 if se060 ==2

gen litstrm 	= 1 if se061 ==4
replace litstrm = 2 if se061 ==3
replace litstrm = 3 if se061 ==2


* EXPOSURE VARS
	* derive binary outcome
xtile pct_rep=repbehaviour, nq(10)
gen b_rep=1 if pct_rep==10
replace b_rep=0 if 1<=pct_rep & pct_rep<10

	* drop variables 
drop pct_* 


	* alternative exposure variable: smoking in pregnancy
replace b650 = . if b650 < 0  // replace missing questionnaire value with missing value (general) 
replace b659 = . if b659 < 0
replace b670 = . if b670 < 0
replace b671 = . if b671 < 0

gen mat_curr_smok = b650 == 1 & b659 != 1 if missing(b650) == 0 // defining current smoker as reporting having been a smoker and not reporting they have now stopped
gen mat_rep_smok = 1 if ( b670 > 0 & missing(b670) == 0 ) ///
						| ( b671 > 0 & missing(b671) == 0 ) 
replace mat_rep_smok = 0 if b670 == 0 & b671 == 0  ///
						| b670 == 0 & missing(b671) == 1 ///
						| missing(b670) == 1 & b671 == 0

gen mat_smok_ANY_18wk = mat_curr_smok == 1  | mat_rep_smok ==1 if missing(mat_curr_smok) + missing(mat_rep_smok) < 2	
	
	


* CONFOUNDERS
	* rename variables 
rename kz021 	sex
rename c645a 	matEd
rename mz028b 	matage
rename b032		parity
rename fh0011a  ageAtIQ  
	
	
	* derive binary race variable
gen whiterace=1 if c800==1
replace whiterace=0 if c800>1

	* derive maternal and paternal highest education
gen 	matEdDrv = 1 if matEd == 2 // vocational 
replace matEdDrv = 2 if matEd == 1 | matEd ==3 // CSE/Olevel
replace matEdDrv = 3 if matEd == 4 | matEd == 5  // A level/Degree

	* Derive maternal age groups
replace matage=. 	  if matage<0
egen matage_grp = cut(matage), at(0,25,30,35,100) icodes

	* derive parity as a categorical variable
egen parity_cat = cut(parity), at(-7,0,1,2,3,25) 
replace parity_cat=. if parity<0
	
	* remove missing values of confounders
replace matEdDrv=. 	  if matEd<0
replace sex=. 		  if sex<0
replace ageAtIQ=.	  if ageAtIQ<0

	* convert selecte confounders to binary 
replace sex=0 if sex==2


* LABELS
label define lab_sex 0 "Female" 1 "Male"
label values sex lab_sex

label define lab_binary 0 "No" 1 "Yes"
label values b_rep lrndif mat_smok_ANY_18wk lab_binary
label var b_rep "Binary repetitive behaviour measure"
label var lrndif "Learning difficulty ever"

label define lab_strm 1 "Lowest" 2 "Middle" 3 "Highest"
label values litstrm mthstrm lab_strm
label var litstrm "Literacy steaming group"
label var mthstrm "Math streaming group"

lab define lab_ed 1 "Vocational" 2 "CSE/O level" 3 "A level/Degree"
lab values matEdDrv lab_ed
lab var matEdDrv "Maternal highest educational qualification (recoded)" 

lab define lab_matage 0 "<= 24 Years old" 1 "25-29 Years old" ///
					  2 "30-34 Years old" 3 ">=35 Years old"  
lab values matage_grp lab_matage
lab var matage_grp "Grouped maternal age"

lab define lab_parity 0 "0" 1 "1" 2 "2" 3 ">=3"
lab values parity_cat lab_parity
lab var parity_cat "Parity Categories"

lab var nmIQ_8 "IQ at age 4 - WPPSI"
lab var nmIQ_8 "IQ at age 8 - WISC"
lab var nmIQ_9 "Intelligibility and fluency at age 9 - CCC"
lab var nmIQ_15 "IQ at age 15 - WASI"
lab var tstscre "Maths assessment score at year 6 (Percentage from 35 items)"

label var mat_smok_ANY_18wk "Any maternal smoking during pregnancy (Y/N) comparable with paternal report"



* remove unneeded variables
keep aln qlet kz011b nmIQ_15 b_rep mat_smok_ANY_18wk ///
nmIQ_4 nmIQ_8 nmIQ_9 tstscre lrndif litstrm mthstrm ///
matage_grp parity_cat sex matEdDrv

* save derived vars
save "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\MI_emp_drvdat.dta", replace



use "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\MI_emp_drvdat.dta", clear
********************************************************************************
* Missing data
********************************************************************************
* OUTCOME	
	* derive indicators
egen miss_IQ4 = cut(IQ_4),  at(-100,0,200)
egen miss_IQ8 = cut(IQ_8),  at(-100,0,200)
egen miss_IQ9 = cut(IQ_9),  at(-100,0,200)
egen miss_IQ15= cut(IQ_15), at(-100,0,200)

label define lab_miss -100 "Missing explained" 0 "Not missing" 
label values miss_IQ* lab_miss

gen i_miss_IQ4 = 1 if IQ_4 <0 | missing(IQ_4)==1
replace i_miss_IQ4 = 0 if missing(i_miss_IQ4)==1
gen i_miss_IQ8 = 1 if IQ_8 <0 | missing(IQ_8)==1
replace i_miss_IQ8 = 0 if missing(i_miss_IQ8)==1
gen i_miss_IQ9 = 1 if IQ_9 <0 | missing(IQ_9)==1
replace i_miss_IQ9 = 0 if missing(i_miss_IQ9)==1
gen i_miss_IQ15= 1 if IQ_15<0 | missing(IQ_15)==1
replace i_miss_IQ15 = 0 if missing(i_miss_IQ15)==1

gen tstscre_mis=missing(tstscre)
gen lrndif_mis=missing(lrndif)
gen litstrm_mis=missing(litstrm)
gen mthstrm_mis=missing(mthstrm)


gen miss_quant = i_miss_IQ4 + i_miss_IQ8 + i_miss_IQ9 + i_miss_IQ15
order aln qlet IQ* miss*

tab miss_IQ4,  miss
tab IQ_4 if IQ_4<0

tab miss_IQ8,  miss
tab IQ_8 if IQ_8<0

tab miss_IQ9,  miss
tab IQ_9 if IQ_9<0

tab miss_IQ15, miss
tab IQ_15 if IQ_15<0

tab miss_quant, miss // higher number indicates more values missing
* small number with all data available

tab miss_quant miss_IQ15, miss // just under half (45%) of those with missing IQ @ 15 
							   // have at least one measure of IQ at another time point

tab miss_IQ15 tstscre_mis, mis
tab miss_IQ15 lrndif_mis, mis
tab miss_IQ15 litstrm_mis, mis
tab miss_IQ15 mthstrm_mis, mis
							   
		* check for test score missingness across other categories (for pmm)
egen allcats1=group(matage_grp parity_cat sex matEdDrv)
tab allcats1 tstscre_mis 
	// not sufficient numbers in all groups, should not use pmm
							   
* EXPOSURE
tab repbehaviour, miss	
tab repbehaviour miss_quant, miss
tab repbehaviour miss_IQ15, miss 

* CONFOUNDERS
gen matage_mis	=missing(matage_grp)
gen parity_mis	=missing(parity_cat)
gen sex_mis		=missing(sex)
gen ageAtIQ_mis =missing(ageAtIQ)
gen matEdDrv_mis=missing(matEdDrv)

gen misConf	=matage_mis + parity_mis + sex_mis + ageAtIQ_mis + matEdDrv_mis

tab matage_mis	
tab parity_mis	
tab sex_mis		
tab ageAtIQ_mis 
tab matEdDrv_mis
tab misConf

	* remove age at IQ measurement
		* Justification: lots of missing confounder data will cause problem in 
		* imputation model (will have to impute as well). Also I don't think this 
		* is really a confounder between exposure and outcome. However age is related
		* to IQ score (see sections below)
gen misConf2	=matage_mis + parity_mis + sex_mis + matEdDrv_mis
tab misConf2


********************************************************************************
* Distributions
********************************************************************************
* EXPOSURE
tab repbehaviour, missing
tab b_rep

* OUTCOME 
hist nmIQ_15

* AUXILIARY VARIABLES
hist nmIQ_4
hist nmIQ_8
hist nmIQ_9

hist tstscre
tab litstrm
tab mthstrm		
tab lrndif			

* CONFOUNDING VARIABLES	   
tab matage_grp	
tab parity_cat
tab sex
tab matEdDrv
	
********************************************************************************
* Correlations and cross tabulations
********************************************************************************
* EXPOSURE
estpost tabstat nmIQ_15, ///
	by(b_rep) stat(mean sd p25 p50 p75) columns(statistics) listwise


* AUXILIARY VARIABLES
cor nmIQ_* // high correlation for IQ @ 15 with IQ measures at 4 and 8 but not 9
regress nmIQ_15 nmIQ_4
regress nmIQ_15 nmIQ_8
regress nmIQ_15 nmIQ_9

cor nmIQ_15 tstscre
regress nmIQ_15 tstscre

estpost tabstat nmIQ_15, ///
	by(litstrm) stat(mean sd p25 p50 p75) columns(statistics) listwise
regress nmIQ_15 i.litstrm
regress nmIQ_15 litstrm

	
estpost tabstat nmIQ_15, ///
	by(mthstrm) stat(mean sd p25 p50 p75) columns(statistics) listwise
regress nmIQ_15 i.mthstrm
regress nmIQ_15 mthstrm

	
estpost tabstat nmIQ_15, ///
	by(lrndif) stat(mean sd p25 p50 p75) columns(statistics) listwise
regress nmIQ_15 i.lrndif


* CONFOUNDERS
estpost tabstat nmIQ_15, ///
	by(matage_grp) stat(mean sd p25 p50 p75) columns(statistics) listwise
regress nmIQ_15 i.matage_grp
regress nmIQ_15 ib(freq).matage_grp

regress nmIQ_15 i.parity_cat

estpost tabstat nmIQ_15, ///
	by(sex) stat(mean sd p25 p50 p75) columns(statistics) listwise

estpost tabstat nmIQ_15, ///
	by(matEdDrv) stat(mean sd p25 p50 p75) columns(statistics) listwise
	
regress nmIQ_15 ageAtIQ

********************************************************************************
* CCA Regression models
********************************************************************************
regress nmIQ_15 repbehaviour
regress nmIQ_15 repbehaviour  matage_grp parity i.sex i.matEdDrv
	
regress nmIQ_15 b_rep
regress nmIQ_15 b_rep matage_grp parity i.sex i.matEdDrv

	
********************************************************************************
log close	
	
