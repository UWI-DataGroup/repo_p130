**  DO-FILE METADATA
//  algorithm name				SickleCell_ass.do
//  project:					acute splenic sequestration  in SCD
//  analysts:					Christina HOWITT

** General algorithm set-up
version 17
clear all
macro drop _all
set more 1
set linesize 80

** Set working directories: this is for DATASET and LOGFILE import and export
** DATASETS to encrypted SharePoint folder
local datapath "X:\The University of the West Indies\DataGroup - repo_data\data_p130"
** LOGFILES to unencrypted OneDrive folder
local logpath X:\OneDrive - The University of the West Indies\repo_datagroup\repo_p130

** Close any open log fileand open a new log file
capture log close
cap log using "`logpath'\scdpreg_001", replace

**Open dataset
import excel "`datapath'\version01\1-input\ASS Factors influencing first event (Christina).xlsx", sheet("Sheet1") firstrow


/*Question 1  Does HbF level at 5 years correlate with age at first event of ASS (my preliminary analysis suggests a strong positive correlation).  
If confirmed, is this relationship modulated by i) alpha thal status, ii) haplotype.*/

replace Hb5y = "" in 21
replace Hb5y = "" in 23
replace Hb5y = "" in 60
replace Hb5y = "" in 62
replace Hb5y = "" in 65
destring Hb5y, replace

regress Hb5y Age

*alpha thal status
replace AT = "" in 20
replace AT = "" in 21
replace AT = "" in 23
replace AT = "" in 42
replace AT = "" in 60
replace AT = "" in 62
replace AT = "" in 65
destring AT, replace 
recode AT 11=1 12=2 22=3
label define AT 1 "homozygous" 2 "heterozygous" 3 "normal"
label values AT AT

regress Hb5y Age AT 

*haplotype
replace haplotype = "" in 3
replace haplotype = "" in 20
replace haplotype = "" in 21
replace haplotype = "" in 23
replace haplotype = "" in 39
replace haplotype = "" in 42
replace haplotype = "" in 46
replace haplotype = "" in 51
replace haplotype = "" in 56
replace haplotype = "" in 57
replace haplotype = "" in 59
replace haplotype = "" in 60
replace haplotype = "" in 62
replace haplotype = "" in 63
replace haplotype = "" in 65
destring haplotype, replace

regress Hb5y Age haplotype

regress Hb5y Age AT haplotype

/*Question 2 Is duration of splenomegaly (column T) influenced by HbF level? – we must exclude splenectomies from this analysis 
as the duration was artificially shortened.
*/

replace agesplenect = "99" in 21
replace agesplenect = "99" in 22
replace agesplenect = "99" in 23
destring agesplenect, replace
drop if agesplenect!=.

regress duration Hb5y 

/*Question 3  Is there any evidence of secular distribution in ASS?  My preliminary analysis suggests there is none looking at prevalence by month – 
the importance of this observation is whether viral or other infections could contribute to ASS where the precipitating factors are unknown. 
*/
encode Month, generate(month2)
gen case = 1
collapse (sum) case, by(month2) 
