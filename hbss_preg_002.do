**  DO-FILE METADATA
//  algorithm name				hbss_preg.do
//  project:				    Pregnancy outcomes in SCD (revisions to paper in Nov 2020)
//  analysts:					Christina HOWITT

** General algorithm set-up
version 15
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
cap log using "`logpath'\scdpreg_002", replace


***************************************************************************************************************************************************************
* MATERNAL SES comparison 10th November 2020
***************************************************************************************************************************************************************
import excel "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\Coh SS pregnancy social details.xlsx", sheet("Sheet1") firstrow clear 
drop Name 
gen genotype=1
replace BF = "" in 52
replace agemum = "" in 10
replace agemum = "" in 11
replace agemum = "" in 52
replace Child = "" in 52
destring BF, replace 
destring agemum, replace 
destring Child, replace 

tempfile SSsep
save `SSsep'

import excel "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\Coh AA Preg social details.xlsx", sheet("Sheet1") firstrow clear 
drop Name 
gen genotype=0

replace agemum = "" in 36
replace agemum = "" in 44
destring agemum, replace

append using `SSsep'

codebook agemum if genotype==1
codebook agemum if genotype==0
ttest agemum, by(genotype)
codebook Child if genotype==1
codebook Child if genotype==0
ttest Child, by(genotype) 
codebook BF if genotype==1
codebook BF if genotype==0
ttest BF, by(genotype)
ranksum agemum, by (genotype)
ranksum Child, by (genotype)
ranksum BF, by (genotype)


*/*************************************************************************************************************************************************************
* MATERNAL CONFOUNDERS ANALYSIS 18TH NOVEMBER 2020
***************************************************************************************************************************************************************
import excel "`datapath'\version01\1-input\Coh SS pregnancy confounders.xlsx", sheet("Sheet1") firstrow clear 

        *data management
            drop Name 
            gen genotype=1
            encode married, gen(marstat)
            order marstat, after(married)
            replace BF = "" in 39
            replace BF = "" in 48
            replace BF = "" in 50
            replace BF = "" in 52
            replace BF = "" in 53
            replace BF = "" in 63
            replace BF = "" in 65
            destring BF, replace 
            replace livech = "0" in 53
            destring livech, replace 

        *table 1 baseline descriptives
        tab marstat, miss
        summarize livech
        summarize BF
        summarize contacts


*merge with SS pregnancy full dataset
        keep ID genotype Coh marstat BF livech contacts

merge 1:m ID using "`datapath'\version01\1-input\cohort_SSpreg.dta"
drop _merge
save "`datapath'\version01\1-input\SS_preg_conf.dta", replace 

**AA CONTROLS
import excel "`datapath'\version01\1-input\Coh AA Preg patients confounders(v2).xlsx", sheet("Sheet1") firstrow clear 
        *data management
        drop Name 
        gen genotype=0
        encode married, gen(marstat)
        order marstat, after(married)

        *table 1 descriptives
        tab marstat, miss
        gen marstat1 = .
        replace marstat1 = 1 if marstat == 1 | marstat == 2 | marstat ==3
        replace marstat1 = 2 if marstat == 4
        replace marstat1 = 2 if marstat == 5
        replace marstat1 = 3 if marstat == 6
        replace marstat1 = 4 if marstat == 7 | marstat ==8
        label define marstat1 1 "Separated/Divorced" 2 "Married" 3 "Single" 4 "Co-habiting"
        label values marstat1 marstat1
        drop marstat
        rename marstat1 marstat
        rename Child livech 
        summarize livech
        summarize BF
        summarize contacts
        keep ID genotype Coh marstat BF livech contacts

*merge with prepared full pregnancy dataset
merge 1:m ID using "`datapath'\version01\1-input\cohort_AApreg.dta", force
drop _merge

*Combine with SS full dataset with confounders
append using "`datapath'\version01\1-input\SS_preg_conf.dta", force



**************************************************************************************
*	Table 2: Selected characteristics and pregnancy outcomes of subjects and controls
**************************************************************************************
**set mother as cluster unit
xtset ID

**PREGNANCY OUTCOME 
**dropping one twin pregnancy from AA controls, as twin pregnancies change many of the features associated with pregnancy outcome.
drop if ID==1256 & pregtot==3
*Pregnancy outcome
tab delivery genotype, col

gen preg_out=.
replace preg_out=1 if delivery==1 | delivery==2 | delivery==5
replace preg_out=2 if delivery==3
replace preg_out=3 if delivery==4
replace preg_out=4 if delivery==6
replace preg_out=5 if delivery==7
label define preg_out 1 "Live birth" 2 "Stillbirth" 3 "Surgical termination of pregnancy" 4 "Spontaneous abortion" 5 "Ectopic"
label values preg_out preg_out
tab preg_out genotype, col



*Termination
gen term=.
replace term=1 if preg_out==3
replace term=0 if preg_out==1 | preg_out==2 | preg_out==4 | preg_out==5
label variable term "termination"
label values term yesno
tab term genotype, col
xtgee term genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee term genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*spontaneous Abortion
gen spab=0 
replace spab=1 if delivery==6
replace spab=. if delivery==. | delivery==3
tab spab genotype, chi2 col
xtgee spab genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee spab genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*stillbirth - generate binary variable
gen sbirth=.
replace sbirth=1 if preg_out==2
replace sbirth=0 if preg_out==1 | preg_out==4 | preg_out==5
label variable sbirth "stillbirth"
label values sbirth yesno
tab sbirth genotype, col chi exact
xtgee sbirth genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee sbirth genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*ectopic pregnancy
replace ect=. if preg_out==3
tab ect genotype, chi2 exact col

*live birth - generate binary variable
gen lbirth=.
replace lbirth=1 if preg_out==1
replace lbirth=0 if preg_out==2 | preg_out==4 | preg_out==5
label variable lbirth "live birth"
label define yesno 1 "Yes" 0 "No"
label values lbirth yesno
tab lbirth genotype, chi2 col
xtgee lbirth genotype, family(binomial) link(log) corr(exchangeable) eform
*xtgee lbirth genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*neonatal deaths
gen nnd=0
replace nnd=1 if ID==2825 & pregtot==3
replace nnd=1 if ID==2320 & pregtot==3
replace nnd=1 if ID==1381 & pregtot==1
replace nnd=1 if ID==2519 & pregtot==2
tab nnd genotype, chi2 exact col
xtgee nnd genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee nnd genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*gestational age
gen gest24=.
replace gest24=0 if gest<24
replace gest24=1 if gest >= 24 & gest <.
gen lg2=.
replace lg2=1 if gest24==1 & gest < 37 
replace lg2=0 if gest24==1 & gest >=37 & gest <.
tab lg2 genotype, col
xtgee lg2 genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee lg2 genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*birthweight
replace BW=. if lbirth!=1
codebook BW if genotype==1
codebook BW if genotype==0
ranksum BW, by(genotype)
tab bw_cat genotype, col
xtgee bw_cat genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee bw_cat genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform
*birthweight after controlling for gestational age
bysort genotype: sum BW
regress BW genotype
regress BW genotype gest

*low Apgar 
numlabel, add mask("#")
label values lowAPGAR5 lowAPGAR5
replace lowAPGAR5=. if lbirth==0
replace lowAPGAR5=. if nnd==1
tab lowAPGAR5 genotype, col chi exact
xtgee lowAPGAR5 genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee lowAPGAR5 genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*delivery details for live deliveries
gen deldet=.
replace deldet=1 if delivery==1 | delivery==2
replace deldet=2 if delivery==5
label variable deldet "details of delivery"
label define deldet 1 "caesarian" 2 "vaginal"
label values deldet deldet
tab deldet genotype, col

*caesarian
gen ces=.
replace ces=1 if deldet==1
replace ces=0 if deldet==2
label variable ces "caesarian section"
label values ces yesno
tab ces genotype, col
xtgee ces genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee ces genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*Acute chest syndrome
tab ACS genotype, chi2 exact
xtgee ACS genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee ACS genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*UTI
tab UTI genotype, col chi2 exact
xtgee UTI genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee UTI genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*Antepartum haemorrhage
tab APH genotype, chi2 exact
xtgee APH genotype, family(binomial) link(log) corr(exchangeable) eform

*Post partum haemorrhage
tab PPH genotype, chi2 exact
xtgee PPH genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee PPH genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*Pregnancy induced hypertension
tab PIH genotype, col
xtgee PIH genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee PIH genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*Pre-eclampsia & eclampsia
tab PET genotype, chi2 exact expected col
xtgee PET genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee PET genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*Retained placenta
tab retplac genotype, chi2 exact col
xtgee retplac genotype, family(binomial) link(log) corr(exchangeable) eform
xtgee retplac genotype aap marstat contacts, family(binomial) link(log) corr(exchangeable) eform


*sepsis
tab sep genotype, chi2 exact col

*maternal deaths
tab Death genotype, chi2 exact col







/*graham sent new dataset to use for BW 
import excel "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\Cohort  SS-AA pregnancy comparison - GA.xlsx", firstrow sheet("Sheet1") clear

gen bw_cat=.
replace bw_cat=1 if BW<2.5
replace bw_cat=0 if BW>=2.5 & BW<.
label variable bw_cat "birthweight category"
label define bw_cat 1 "<2.5" 0 ">=2.5"
label values bw_cat bw_cat
tab bw_cat, miss
tab bw_cat genotype, col

xtset ID
xtgee bw_cat gtype2, family(binomial) link(log) corr(exchangeable) eform
