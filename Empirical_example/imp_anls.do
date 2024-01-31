set more off
set logtype text
log using "/panfs/panasas01/sscm/pm0233/mi_miniproject/empirical/log_imp_anls_nomiss_exp.txt", replace
********************************************************************************
* Author: Paul Madley-Dowd
* Date: 13 Jun 2018
* Description: MI empirical example imputation analysis using observed exposure data only
********************************************************************************

version 14.1


cd /panfs/panasas01/sscm/pm0233/mi_miniproject/empirical
use "./Data/MI_emp_drvdat.dta", clear


* create variable list to retain all variables later
describe, varlist
local allvar = r(varlist)

* drop if infant did not survive to 1 year
drop if kz011b==2

* drop if missing confounder variables
	* justification that if they are missing these they are likely to be missing lots of data
keep if missing(matage_grp, parity_cat, sex, matEdDrv)==0



* set initial seed 
set seed 75329


* create local variables for variable lists
local conf_i =  "i.matage_grp i.parity_cat i.sex i.matEdDrv"

local aux1  = "nmIQ_4"
local aux2  = "nmIQ_8"
local aux3  = "nmIQ_9"
local aux4  = "tstscre"
local aux5  = "lrndif"
local aux6  = "litstrm mthstrm"
local aux7  = "nmIQ_8 nmIQ_9"
local aux8  = "nmIQ_8 tstscre"
local aux9  = "nmIQ_8 nmIQ_9 tstscre"
local aux10 = "nmIQ_8 nmIQ_9 tstscre lrndif"
local aux11 = "nmIQ_8 nmIQ_9 tstscre litstrm mthstrm"
local aux12 = "nmIQ_8 nmIQ_9 tstscre lrndif litstrm mthstrm"


capture postutil clear
tempname memhold

postfile `memhold' aux str50 model ///
		beta0  beta0_se beta0_fmi beta1 beta1_se beta1_fmi  ///
		unadj_beta0  unadj_beta0_se unadj_beta0_fmi unadj_beta1 unadj_beta1_se unadj_beta1_fmi  ///
		using "./Results/emp_anls_out_nomiss_exp.dta", replace


forvalues j = -1(1)12 {

	disp "j = `j'"	
	local nimp = 1000
	local burn = 10
	
	
	if `j'==-1 {		// Complete Case Analysis
		
		* Adjusted analysis
		regress nmIQ_15 mat_smok_ANY_18wk `conf_i'
		
		*store output values in matrices
		matrix mcca_b		=e(b)	
		matrix mcca_V		=e(V)	
		local nvar_cca=rowsof(mcca_V) // position of the b0 in the matrix
		disp "nvars cca = " `nvar_cca'

		
		* store individual values in macro variables
		local auxmodel		=`j'
		local model 		="cca"
		local beta0    		= mcca_b[1,`nvar_cca']
		local beta1   	 	= mcca_b[1,1] 
		local beta0_se 		= sqrt(mcca_V[`nvar_cca',`nvar_cca'])
		local beta1_se 		= sqrt(mcca_V[1,1])	
		local beta0_fmi		= 999
		local beta1_fmi 	= 999


		* Unadjusted analysis
		regress nmIQ_15 mat_smok_ANY_18wk 
		
		*store output values in matrices
		matrix un_mcca_b		=e(b)	
		matrix un_mcca_V		=e(V)	
		
		* store individual values in macro variables
		local un_beta0    		= un_mcca_b[1,2]	
		local un_beta1   	 	= un_mcca_b[1,1] 
		local un_beta0_se 		= sqrt(un_mcca_V[2,2])
		local un_beta1_se 		= sqrt(un_mcca_V[1,1])	
		local un_beta0_fmi		= 999
		local un_beta1_fmi 		= 999



		
	}
	else if `j'>=0 {  // Imputation models
		
		* MI prep
		mi set mlong
		mi register imputed nmIQ_15 mat_smok_ANY_18wk `aux`j''

		* Imputation models	
		if `j'==0{
			mi impute chained ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="No aux info"
		}
		else if `j'==1{
			mi impute chained ///
				(regress) nmIQ_4  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 4 as aux info"
		}
		else if `j'==2{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
				
			local model="IQ @ 8 as aux info"
		}
		else if `j'==3{
			mi impute chained ///
				(regress) nmIQ_9  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
				
			local model="IQ @ 9 as aux info"
		}
		else if `j'==4{
			mi impute chained ///
				(regress) tstscre  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	

			local model="Maths assessment @ year 6 as aux"
		}
		else if `j'==5{
			mi impute chained ///
				(logit) lrndif  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
				
			local model="Learning difficulties as aux info"
		}
		else if `j'==6{
			mi impute chained ///
				(ologit) mthstrm  ///
				(ologit) litstrm  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="Math and literacy streaming group as aux info"
		}	
		else if `j'==7{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_9  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and 9 as aux info"
		}		
		else if `j'==8{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) tstscre  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and math ass. @ yr 6 as aux info"
		}
		else if `j'==9{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_9  ///
				(regress) tstscre  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and 9 and math ass. @ yr 6 as aux info"
		}		
		else if `j'==10{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_9  ///
				(regress) tstscre  ///
				(logit) lrndif  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and 9, math ass. and LD as aux info"
		}		
		else if `j'==11{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_9  ///
				(regress) tstscre  ///
				(ologit) mthstrm  ///
				(ologit) litstrm  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and 9, math ass. and streaming groups as aux info"
		}		
		else if `j'==12{
			mi impute chained ///
				(regress) nmIQ_8  ///
				(regress) nmIQ_9  ///
				(regress) tstscre  ///
				(logit) lrndif  ///
				(ologit) mthstrm  ///
				(ologit) litstrm  ///
				(regress) nmIQ_15 = mat_smok_ANY_18wk `conf_i' ///
				, add(`nimp')	burnin(`burn')	
			
			local model="IQ @ 8 and 9, math ass., LD and streaming groups as aux info"
		}		
	
	
		* Combine estimates (adjusted)
		mi estimate , : regress nmIQ_15 mat_smok_ANY_18wk `conf_i' 


		*store output values in matrices
		matrix m`j'_fmi		=e(fmi_mi)
		matrix m`j'_b		=e(b_mi)	
		matrix m`j'_V		=e(V_mi)
		local nvars=rowsof(m`j'_V) // position of the b0 in the matrix
		disp "nvars = " `nvars'

		* store individual values in macro variables
		local auxmodel		=`j'
		local beta0_fmi		= m`j'_fmi[1,`nvars']
		local beta1_fmi 	= m`j'_fmi[1,1]
		local beta0    		= m`j'_b[1,`nvars']
		local beta1   	 	= m`j'_b[1,1] 
		local beta0_se 		= sqrt(m`j'_V[`nvars',`nvars'])
		local beta1_se 		= sqrt(m`j'_V[1,1])




		* Combine estimates (unadjusted)
		mi estimate , : regress nmIQ_15 mat_smok_ANY_18wk 


		*store output values in matrices
		matrix un_m`j'_fmi		=e(fmi_mi)
		matrix un_m`j'_b		=e(b_mi)	
		matrix un_m`j'_V		=e(V_mi)

		* store individual values in macro variables
		local un_beta0_fmi		= un_m`j'_fmi[1,2]
		local un_beta1_fmi 		= un_m`j'_fmi[1,1]
		local un_beta0    		= un_m`j'_b[1,2]
		local un_beta1   	 	= un_m`j'_b[1,1] 
		local un_beta0_se 		= sqrt(un_m`j'_V[2,2])
		local un_beta1_se 		= sqrt(un_m`j'_V[1,1])



		

		* Unregister dataset as MI
		mi unregister nmIQ_15 mat_smok_ANY_18wk `aux`j''

		
		* reset dataset to original form
		mi unset
		keep `allvar'
	}

	disp "j = " `auxmodel' 
	disp "`model'"
	disp "b0 = " 		`beta0' 
	disp "se(b0) = " 	`beta0_se'
	disp "fmi(b0) = " 	`beta0_fmi'
	disp "b1 = " 		`beta1' 
	disp "se(b1) = " 	`beta1_se' 
	disp "fmi(b1) = " 	`beta1_fmi'

	disp "unadjusted b0 = " 	`un_beta0' 
	disp "unadjusted se(b0) = " 	`un_beta0_se'
	disp "unadjusted fmi(b0) = " 	`un_beta0_fmi'
	disp "unadjusted b1 = " 	`un_beta1' 
	disp "unadjusted se(b1) = " 	`un_beta1_se' 
	disp "unadjusted fmi(b1) = " 	`un_beta1_fmi'

	
	if `j' == 1 | `j' == 5 | `j' == 12 { // test that correct FMI values are being taken
		matrix list m`j'_fmi
		matrix list un_m`j'_fmi
	}
	
	disp " ------------ end of model `j'--------------"
	
	* POST THE RESULTS TO THE DATASET
	post `memhold' (`auxmodel') ("`model'") ///
		(`beta0') (`beta0_se') (`beta0_fmi') ///
		(`beta1') (`beta1_se') (`beta1_fmi') ///
		(`un_beta0') (`un_beta0_se') (`un_beta0_fmi') ///
		(`un_beta1') (`un_beta1_se') (`un_beta1_fmi') 

}

postclose `memhold'

use "./Results/emp_anls_out_nomiss_exp.dta", clear
replace beta0_fmi=. if beta0_fmi==999
replace beta1_fmi=. if beta1_fmi==999
replace unadj_beta0_fmi=. if unadj_beta0_fmi==999
replace unadj_beta1_fmi=. if unadj_beta1_fmi==999

save, replace


********************************************************************************
********************************************************************************
log close
