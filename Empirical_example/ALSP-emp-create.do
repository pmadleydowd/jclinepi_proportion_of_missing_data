*** Syntax template for direct users preparing datasets using child and adult based datasets.

* This version created 29th October 2014 - always create a datafile using the most up to date template.

* This template is based on that used by the data buddy team and they include a number of variables by default.
* To ensure the file works we suggest you keep those in and just add any relevant variables that you need for your project.


****************************************************************************************************************************************************************************************************************************
* To add data other than that included by default you will need to add the relvant files and pathnames in each of the match commands below.
* There is a separate command for mothers, partner, mothers providing data on the child and data provided by the child themselves.
* each has different withdrawal of consent issues so they must be considered separately.
* You will need to replace 'YOUR PATHNAME' in each section with your working directory pathname.

*****************************************************************************************************************************************************************************************************************************.

* MOTHER files - in this section the following files need to be placed:
* Mother completed Qs about herself
* Mother clinic data
* Mother biosamples *

clear
set maxvar 32767	
use "R:\Data\Current\Other\Sample Definition\mz_5a.dta", clear
sort aln
gen in_mz=1
merge 1:1 aln using "R:\Data\Current\Quest\Mother\a_3c.dta", nogen
merge 1:1 aln using "R:\Data\Current\Quest\Mother\b_4d.dta", nogen
merge 1:1 aln using "R:\Data\Current\Quest\Mother\c_7d.dta", nogen
merge 1:1 aln using "R:\Data\Useful_data\bestgest\bestgest.dta", nogen

keep aln mz001 mz010 mz010a mz013 mz014 mz028b ///
a006 a525 ///
b032 b650 b659 b663 - b667 b670-b671 ///
c525 c645a c666a c755 c765 c800 - c804 ///
bestgest

* Dealing with withdrawal of consent: For this to work additional variables required have to be inserted before bestgest, so replace the *** line above with additional variables. 
* If none are required remember to delete the *** line.
* An additional do file is called in to set those withdrawing consent to missing so that this is always up to date whenever you run this do file

order aln mz010, first
order bestgest, last

do "R:\Data\Syntax\Withdrawal of consent\mother_quest_WoC.do"


save "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\mother.dta", replace


*****************************************************************************************************************************************************************************************************************************.
* PARTNER - ***UNBLOCK SECTION WHEN REQUIRED***
* Partner files - in this section the following files need to be placed:
* Partner completed Qs about themself
* Partner clinic data
* Partner biosamples data *

/* use "R:\Data\Current\Quest\Partner\***.dta, clear
merge 1:1 aln using "R:\Data\Current\Quest\Partner\***.dta", nogen
keep aln varlist
save "YOUR PATHNAME\partner.dta", replace */


*****************************************************************************************************************************************************************************************************************************.
* Child BASED files - in this section the following files need to be placed:
* Mother completed Qs about YP

* ALWAYS KEEP THIS SECTION EVEN IF ONLY CHILD COMPLETED REQUESTED, although you will need to remove the *****

use "R:\Data\Current\Other\Sample Definition\kz_5b.dta", clear
sort aln qlet
gen in_kz=1
merge 1:1 aln qlet using "R:\Data\Current\Other\cohort profile\cp_r1a.dta", nogen
merge 1:1 aln qlet using "O:\Documents\Projects\Vit D\Analysis\Data\create\autistic traits and ASD diagnoses_hh20170405.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Quest\Child Based\ku_r2b.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Quest\Schools\sefg_1b.dta", nogen 

keep aln qlet kz011b kz021 kz030 ///
ku503a-ku503c ///
scdc coherence repbehaviour sociability autism_new autism_new_confirmed_hh ///
se031a se060-se061 ///
in_core in_alsp in_phase2 in_phase3 tripquad


* Dealing with withdrawal of consent: For this to work additional variables required have to be inserted before in_core, so replace the ***** line with additional variables.
* If none are required remember to delete the ***** line.
* An additional do file is called in to set those withdrawing consent to missing so that this is always up to date whenever you run this do file

order aln qlet kz021, first
order in_alsp tripquad, last

do "R:\Data\Syntax\Withdrawal of consent\child_based_WoC.do"


save "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\childB.dta", replace

*****************************************************************************************************************************************************************************************************************************.
* Child COMPLETED files - in this section the following files need to be placed:
* YP completed Qs
* Puberty Qs
* Child clinic data
* Child biosamples data

* If there are no child completed files, this section can be starred out.
* NOTE: having to keep kz021 tripquad just to make the withdrawal of consent work - these are dropped for this file as the ones in the child BASED file are the important ones and should take priority

use "R:\Data\Current\Other\Sample Definition\kz_5b.dta", clear
sort aln qlet
merge 1:1 aln qlet using "R:\Data\Current\Other\cohort profile\cp_r1a.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Clinic\Child\tf3_r2d.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Clinic\Child\f08_4a.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Clinic\Child\cif_7a.dta", nogen
merge 1:1 aln qlet using "R:\Data\Current\Quest\Schools\sh_1b.dta", nogen


keep aln qlet kz021 ///
fh0011a fh6280-fh6281 f8ws110-f8ws115 cf811-cf813 ///
sh370-sh371 ///
tripquad

* Dealing with withdrawal of consent: For this to work additional variables required have to be inserted before tripquad, so replace the ***** line with additional variables.
* An additional do file is called in to set those withdrawing consent to missing so that this is always up to date whenever you run this do file

order aln qlet kz021, first
order tripquad, last

do "R:\Data\Syntax\Withdrawal of consent\child_completed_WoC.do"


drop kz021 tripquad
save "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\childC.dta", replace

*****************************************************************************************************************************************************************************************************************************.
** Matching all data together and saving out the final file*.
* NOTE: any linkage data should be added here*.

use "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\childB.dta", clear
merge 1:1 aln qlet using "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\childC.dta", nogen
merge m:1 aln using "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\mother.dta", nogen
* IF partner data is required please unstar the following line
/* merge m:1 aln using "YOUR PATHWAY\partner.dta", nogen */


* Remove non-alspac children.
drop if in_alsp!=1.

* Remove trips and quads.
drop if tripquad==1

drop in_alsp tripquad
save "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\MI_emp_dat.dta", replace

*****************************************************************************************************************************************************************************************************************************.
* QC checks*
use "O:\Documents\Year 1\Mini project 1 MULTIPLE IMPUTATION\empirical example\Data\MI_emp_dat.dta", clear

* Check that there are 15445 records.
count
