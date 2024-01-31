*-------------------------------------------------------------------------------	
* Author	 : Paul Madley-Dowd 
* Date		 : 25/01/2018 
* Description: Do file to test the proportions of missing data for MAR mechanism 
* stata vrsn : 14.1
* do file use: mi_cov_auto.do
*			   mi_cov_auto_call.do
* 			   sim_MVN_data_jnt.do
* out dsets  : mimps.dta
*-------------------------------------------------------------------------------	
* Notes		 : ANALYSIS MODEL: Y|X ~ N(beta0 + beta1*X, sigma*sigma)
*-------------------------------------------------------------------------------	

do "O:/Documents/Year 1/Mini project 1 MULTIPLE IMPUTATION/Programming/command_lib/mi_cov_auto.do" 


capture postutil clear
tempname memhold

postfile `memhold' propmiss_1 propmiss_5 propmiss_10 propmiss_20 propmiss_40 propmiss_60 propmiss_80 propmiss_90 ///
	using "O:/Documents/Year 1/Mini project 1 MULTIPLE IMPUTATION/Programming/imp_bias/Data/Create/proptest.dta", replace

forvalues dataset=1(1)100 {
	sim_dat, nobs(1000)

	* MAR missing
	sim_miss , miss_perc(1)
	sim_miss , miss_perc(5)
	sim_miss , miss_perc(10)
	sim_miss , miss_perc(20)
	sim_miss , miss_perc(40)
	sim_miss , miss_perc(60)
	sim_miss , miss_perc(80)
	sim_miss , miss_perc(90)


	summ R1
	local propmiss_1 = 1-r(mean)
	summ R5
	local propmiss_5 = 1-r(mean)
	summ R10
	local propmiss_10 = 1-r(mean)
	summ R20
	local propmiss_20 = 1-r(mean)
	summ R40
	local propmiss_40 = 1-r(mean)
	summ R60
	local propmiss_60 = 1-r(mean)
	summ R80
	local propmiss_80 = 1-r(mean)
	summ R90
	local propmiss_90 = 1-r(mean)
	

	post `memhold' ///
		(`propmiss_1') (`propmiss_5') (`propmiss_10') (`propmiss_20') ///
		(`propmiss_40') (`propmiss_60') (`propmiss_80') (`propmiss_90') /// 
	
}
postclose `memhold'



use "O:/Documents/Year 1/Mini project 1 MULTIPLE IMPUTATION/Programming/imp_bias/Data/Create/proptest.dta",clear

summ propmiss_1
summ propmiss_5
summ propmiss_10
summ propmiss_20
summ propmiss_40
summ propmiss_60
summ propmiss_80
summ propmiss_90

