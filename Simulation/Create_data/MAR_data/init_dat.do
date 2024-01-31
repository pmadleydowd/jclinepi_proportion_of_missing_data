version 14.1


* load automation commands
do "~/mi_miniproject/command_lib/mi_cov_auto.do"


set seed 44324 	// set the seed so that you get the same results everytime you run the exact same experiment
forvalues dataset=1(1)10 {
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

	
	gen dset=`dataset'
		
	save ~/mi_miniproject/imp_bias/Data/sourcedat`dataset', replace
	
}
