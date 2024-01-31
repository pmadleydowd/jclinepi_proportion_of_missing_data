*-------------------------------------------------------------------------------	
* Author	 : Paul Madley-Dowd
* Date		 : 19OCT2016 
* Description: Do file to create automation commands for use in impute.do
*-------------------------------------------------------------------------------	

* Create command to simulate initial data set
capture program drop sim_dat
program define sim_dat
	version 14.1
	syntax , nobs(numlist)
	
	matrix mu = (0,0,0,0,0,0,0,0,0,0,0,0,0)
	matrix rownames mu = mean
	matrix colnames mu = Y X Z1 Z2 Z3 Z4 Z5 Z6 Z7 Z8 Z9 Z10 Z11
	matrix list mu
	  
	matrix Sigma = (1.0,0.6,0.4,0.4,0.2,0.2,0.2,0.2,0.2,0.1,0.1,0.1,0.1 \ ///
					0.6,1,0,0,0,0,0,0,0,0,0,0,0 \ ///
					0.4,0,1,0,0,0,0,0,0,0,0,0,0 \ ///
					0.4,0,0,1,0,0,0,0,0,0,0,0,0 \ ///
					0.2,0,0,0,1,0,0,0,0,0,0,0,0 \ ///
					0.2,0,0,0,0,1,0,0,0,0,0,0,0 \ ///
					0.2,0,0,0,0,0,1,0,0,0,0,0,0 \ ///
					0.2,0,0,0,0,0,0,1,0,0,0,0,0 \ ///
					0.2,0,0,0,0,0,0,0,1,0,0,0,0 \ ///
					0.1,0,0,0,0,0,0,0,0,1,0,0,0 \ ///
					0.1,0,0,0,0,0,0,0,0,0,1,0,0 \ ///
					0.1,0,0,0,0,0,0,0,0,0,0,1,0 \ ///
					0.1,0,0,0,0,0,0,0,0,0,0,0,1 )
	matrix rownames Sigma = Y X Z1 Z2 Z3 Z4 Z5 Z6 Z7 Z8 Z9 Z10 Z11
	matrix colnames Sigma = Y X Z1 Z2 Z3 Z4 Z5 Z6 Z7 Z8 Z9 Z10 Z11
	matrix list Sigma				

	* SIMULATE A DATASET OF 1000 OBSERVATIONS
	clear
	set obs `nobs'
	drawnorm Y X Z1 Z2 Z3 Z4 Z5 Z6 Z7 Z8 Z9 Z10 Z11, means(mu) cov(Sigma)
	
end


* Create command to simulate initial data set with binary outcome
capture program drop sim_dat_bin
program define sim_dat_bin
	version 14.1
	syntax , nobs(numlist)

	clear
	set obs `nobs'
	
	* Simulate X and Z
	matrix mu = (0,0,0,0)
	matrix rownames mu = mean
	matrix colnames mu = X Z1 Z2 Z3 
	matrix list mu
  
	matrix Sigma = (1,0,0,0 \ ///
			0,1,0,0 \ ///
			0,0,1,0 \ ///
			0,0,0,1 ) 

	matrix rownames Sigma = X Z1 Z2 Z3 
	matrix colnames Sigma = X Z1 Z2 Z3 
	matrix list Sigma				

	drawnorm X Z1 Z2 Z3 , means(mu) cov(Sigma)

	* Simulate Y from X and Z	
	local b1=log(2)
	gen lambda	 = `b1'*X + `b1'*Z1 + `b1'*Z2 + `b1'*Z3  - log(0.9455/0.0545)
	gen e_lambda	 = exp(lambda)
	gen lgs_lambda	 = e_lambda/(1+e_lambda)
	gen Y = lgs_lambda >=runiform()
	drop lambda e_lambda lgs_lambda
	
	tab Y	

end



* Create command to create missingness and associated covariates
capture program drop sim_miss
program define sim_miss
	version 14.1
	syntax , miss_perc(numlist)
	
	if `miss_perc'==1{
		local alpha0=5.523
		local alpha1=1
		local alpha2=1
	}
	if `miss_perc'==5{
		local alpha0=3.764
		local alpha1=1
		local alpha2=1
	}
	if `miss_perc'==10{
		local alpha0=2.858
		local alpha1=1
		local alpha2=1
	}
	if `miss_perc'==20{
		local alpha0=1.865
		local alpha1=1
		local alpha2=1
	}
	if `miss_perc'==40{
		local alpha0=0.559
		local alpha1=1
		local alpha2=1
		}
	if `miss_perc'==60{
		local alpha0=-0.558
		local alpha1=1
		local alpha2=1	
	}
	if `miss_perc'==80{
		local alpha0=-1.865
		local alpha1=1
		local alpha2=1
	}
	if `miss_perc'==90{
		local alpha0=-2.858
		local alpha1=1
		local alpha2=1
	}
	
	* Generate the missingness mechanism which depends on both A1 and X
		* lambda = alpha0 + alpha1*Z1 + alpha2*X
		* R = 0 if logistic (lambda) < random draw. R=1 if logistic (lambda) >= random draw
		* R = 0 if missing, 1 if observed
	gen lambda		 = `alpha0'  + `alpha1'*Z1 + `alpha2'*X
	gen e_lambda	 = exp(lambda)
	gen lgs_lambda	 = e_lambda/(1+e_lambda)
	gen R`miss_perc' = lgs_lambda >=runiform()
	
	tab R`miss_perc'	
	pwcorr Y R`miss_perc' X Z1 Z2 Z3
	
	gen Ym`miss_perc'=Y
	replace Ym`miss_perc'=. if R`miss_perc'==0
	
	drop lambda e_lambda lgs_lambda  
end


* Create command for MCAR imputation modelling
capture program drop mcar_imp
program define mcar_imp
	version 14.1
	syntax varlist(min=1 max=12), modno(numlist) miss_perc(numlist)
	
	mi set mlong
	mi register imputed Ymcar`miss_perc' 	

	mi impute regress Ymcar`miss_perc' `varlist', add( 1000 ) 
	mi estimate , : regress Ymcar`miss_perc' X
	
	mi unregister Ymcar`miss_perc' 	

	*store values
	matrix mcar_mi_`miss_perc'_`modno'_mfmi=e(fmi_mi)
	matrix mcar_mi_`miss_perc'_`modno'_b=e(b_mi)	
	matrix mcar_mi_`miss_perc'_`modno'_V=e(V_mi)	
	mi unset
	keep Y-Ymcar90 
		
end;


* Create command to perform MCAR modelling
capture program drop mcar_auto
program define mcar_auto
	version 14.1
	syntax , mis_perc(numlist)
	
	* copied from mi_mod_call
	mcar_imp X, 			modno(1) miss_perc(`mis_perc') 	// no auxiliary info, R2=0.36
	mcar_imp X Z3, 			modno(2) miss_perc(`mis_perc') 	// mild auxiliary info, R2=0.4 
	mcar_imp X Z1, 			modno(3) miss_perc(`mis_perc') 	// moderate auxiliary info, R2=0.52
	mcar_imp X Z1-Z4,	 	modno(4) miss_perc(`mis_perc') 	// good auxiliary info, R2=0.76 
	mcar_imp X Z1-Z11,	 	modno(5) miss_perc(`mis_perc') 	// very good auxiliary info, R2=0.92

		
end;



* Create command for MAR imputation modelling for bias example
capture program drop imp_bias
program define imp_bias
	version 14.1
	syntax varlist(min=1 max=12), miss_perc(numlist)
	
	mi set mlong
	mi register imputed Ym`miss_perc' 	

	mi impute regress Ym`miss_perc' `varlist', add( 1000 ) 
	mi estimate , : regress Ym`miss_perc' X
	
	mi unregister Ym`miss_perc' 	

	*store values
	matrix mi_`miss_perc'_mfmi=e(fmi_mi)
	matrix mi_`miss_perc'_b=e(b_mi)	
	matrix mi_`miss_perc'_V=e(V_mi)	
	mi unset
	keep Y-Ym90 
		
end;


* Create command for MCAR imputation modelling for binary example
capture program drop imp_binout_mcar
program define imp_binout_mcar
	version 14.1
	syntax varlist(min=1 max=12), miss_perc(numlist)

	disp "variables in imputation model: `varlist'"

	
	mi set mlong
	mi register imputed Ymcar`miss_perc' 	

	mi impute logit Ymcar`miss_perc' `varlist', add( 1000 ) 
	mi estimate , : logistic Ymcar`miss_perc' X
	
	mi unregister Ymcar`miss_perc' 	

	*store values
	matrix mi_`miss_perc'_mfmi=e(fmi_mi)
	matrix mi_`miss_perc'_b=e(b_mi)	
	matrix mi_`miss_perc'_V=e(V_mi)	
	mi unset
	keep X-Ymcar90 
		
end;


* Create command for MAR imputation modelling for binary example
capture program drop imp_binout_mar
program define imp_binout_mar
	version 14.1
	syntax varlist(min=1 max=12), miss_perc(numlist)

	disp "variables in imputation model: `varlist'"
	
	mi set mlong
	mi register imputed Ym`miss_perc' 	

	mi impute logit Ym`miss_perc' `varlist', add( 1000 ) 
	mi estimate , : logistic Ym`miss_perc' X
	
	mi unregister Ym`miss_perc' 	

	*store values
	matrix mi_`miss_perc'_mfmi=e(fmi_mi)
	matrix mi_`miss_perc'_b=e(b_mi)	
	matrix mi_`miss_perc'_V=e(V_mi)	
	mi unset
	keep X-Ymcar90 
		
end;
