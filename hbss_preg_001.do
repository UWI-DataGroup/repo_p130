**  DO-FILE METADATA
//  algorithm name				hbss_preg.do
//  project:							Pregnancy outcomes in SCD
//  analysts:							Christina HOWITT
//	date last modified		02-May-2019

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
cap log using "`logpath'\scdpreg_001", replace

**Open dataset
import excel "`datapath'\version01\1-input\Cohort  SS pregnancy  2018 coding Ian-Christina.xlsx", sheet("SS Update") firstrow

*------------------------------------------------------------------------------------------------------------------------------
**DATA PREPARATION
*------------------------------------------------------------------------------------------------------------------------------
drop if ID==.
drop if preg==.
codebook ID
sort ID preg
drop Name Hosp EDD EDDd EDDm EDDy time blloss Notes AX AY AZ BA BB BC BD children gt tx FP ep
gen genotype=1
label define genotype 0 "AA" 1 "SS"
label values genotype genotype
rename preg pregtot
label variable pregtot "number of pregnancies"
label variable Coh "cohort #"
label variable DOB "date of birth"
label variable date "date of status assessment"
label variable age "age at assessment"
label variable menarche "date at menarche"
rename J agem
label variable agem "age at menarche"
label variable LMP "date of last menstrual period"
label variable LMPd "day of last mentrual period"
label variable LMPm "month of last menstrual period"
rename deliv dode1
label variable dode1 "date of pregnancy termination"
label variable DELd "day of pregnancy termination"
label variable DELm "month of pregnancy termination"
label variable DELy "year of pregnancy termination"
rename GA gest
label variable gest "gestational age"
label variable result "outcome of pregnancy"
label variable labourh "duration of labour"
	*remove dots and dashes
	replace labourh = "" in 15
	replace labourh = "" in 24
	replace labourh = "" in 55
	replace labourh = "" in 60
	replace labourh = "" in 137
label variable Indic "Indications for STOP, LSCS"
label variable sx "gender of child"
label variable BW "birthweight"
label variable Apg1 "Apgar 1 minute"
label variable Apg5 "Apgar at 5 minutes"
label variable ANC "visits to antenatal clinic"
	replace ANC = "" in 91
label variable complic "complications at delivery"
label variable Hb "steady state haemoglobin"
label variable MCV "mean cell volume"
destring HFS, gen(HOdactylitis)
bysort ID: replace HOdactylitis=HOdactylitis[1]

*split complic into separate components
split complic, p(,)
order complic, before(complic1)

forval x=1(1)4 {
	destring complic`x', replace
}

forval x=1(1)24 {
	gen comp`x'=0
	replace comp`x'=1 if complic1==`x' | complic2==`x' | complic3==`x' | complic4==`x'
	}
drop complic1 complic2 complic3 complic4

rename comp1 PPH
label variable PPH "post-partum haemorrhage"
rename comp2 shir
label variable shir "Shirodkar"
rename comp3 PIH
label variable PIH "pregnancy-induced HTN"
rename comp4 retplac
label variable retplac "retained placenta"
rename comp5 PET
label variable PET "pre-eclampsia"
rename comp6 UTI
rename comp7 cdef
label variable cdef "congenital deformity"
rename comp8 APH
label variable APH "antepartum haemorrhage"
rename comp9 ectp
label variable ectp "ectopic pregnancy"
rename comp10 ACS
label variable ACS "acute chest syndrome"
rename comp11 anaem
label variable anaem "severe anaemia"
rename comp12 breech
rename comp13 BBA
rename comp14 forcep
rename comp15 haemat
label variable haemat "haematoma"
rename comp16 pcrisis
label variable pcrisis "painful crisis"
rename comp17 adplac
label variable adplac "adherent placenta"
rename comp18 sep
label variable sep "sepsis"
rename comp19 DC
rename comp20 Death
label variable Death "Maternal death"
rename comp21 heps
label variable heps "hepatic sequestration"
rename comp22 CRF
rename comp23 SAH
rename comp24 jaun
label variable jaun "deep jaundice"

** AGE
bysort ID: replace DOB=DOB[1]
gen aap = (dode1 - DOB)/365.25
order aap, after(dode1)
label var aap "Age at pregnancy (in years)"

**generate gravida based on gestational age
codebook gest
gen gravida1 =.
replace gravida1=1 if gest<.
bysort ID: egen gravida= sum(gravida1)
replace gravida=0 if gest==.
order gravida gravida1, after (pregtot)
drop gravida1
order gest, after (gravida)
codebook gravida
summarize gravida

**generating parity (defined as pregnancies >24 weeks regardless of outcome)
gen parity1=.
replace parity1=1 if gest<. & gest>24
bysort ID: egen parity=sum(parity1)
replace parity=0 if gest==.
drop parity1
order parity, after(gravida)
*histogram parity
codebook parity
summarize parity

**morbidity (number and proportion)
tab pcrisis, miss
tab ACS, miss
tab UTI, miss
tab PIH, miss
**maternal morbidity is defined as have any of the following during pregnancy: pcrisis ACS PET UTI APH retplac PPH sep PIH anaem heps eclam // note that in 2019 version of dataset, there is no eclampsia or painful crisis variable
gen mat_morb=0
replace mat_morb=1 if pcrisis==1 | ACS==1 | PET==1 | UTI==1 | APH==1 | retplac==1 | PPH==1 | sep==1 | PIH==1 | anaem==1 | heps==1
order mat_morb, before(ACS)
label variable mat_morb "maternal morbidity"
label values mat_morb noyes
tab mat_morb

**Pregnancy outcome (type of delivery) to be tidied up as follows: 
tab result

/*
outcome of |
  pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
        CCS |          2        1.13        1.13 (classical caesarian section) (successful)
       LSCS |         29       16.38       17.51 (lower segment caesarian section) (successful)
         SB |         11        6.21       23.73 (stillbirth) (unsuccessful)
        SB  |          3        1.69       25.42 (stillbirth) (unsuccessful)
       STOP |         14        7.91       33.33 (Surgical Termination of pregnancy) (unsuccessful)
        SVD |         62       35.03       68.36 (spontaneous vaginal delivery)
       Spab |         54       30.51       98.87 (Spontaneous Abortion) (unsuccessful)
       spab |          2        1.13      100.00 (Spontaneous Abortion) (unsuccessful)
------------+-----------------------------------
      Total |        177      100.00									*/

encode result, gen(delivery)
order delivery, after(result)
numlabel, add mask("#",)
tab delivery
/*outcome of |
 pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
    1 ,CCS |          2        1.13        1.13
   2 ,LSCS |         29       16.38       17.51
     3 ,SB |         11        6.21       23.73
    4 ,SB  |          3        1.69       25.42
   5 ,STOP |         14        7.91       33.33
    6 ,SVD |         62       35.03       68.36
   7 ,Spab |         54       30.51       98.87
   8 ,spab |          2        1.13      100.00
------------+-----------------------------------
     Total |        177      100.00               */

recode delivery 4=3
recode delivery 8=7
tab delivery
/*
outcome of |
  pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
     1 ,CCS |          2        1.13        1.13
    2 ,LSCS |         29       16.38       17.51
      3 ,SB |         14        7.91       25.42
    5 ,STOP |         14        7.91       33.33
     6 ,SVD |         62       35.03       68.36
    7 ,Spab |         56       31.64      100.00
------------+-----------------------------------
      Total |        177      100.00                */


gen delivery1=.
replace delivery1=1 if delivery==1
replace delivery1=2 if delivery==2
replace delivery1=3 if delivery==3
replace delivery1=4 if delivery==5
replace delivery1=5 if delivery==6
replace delivery1=6 if delivery==7
label define delivery1 1 "CCS" 2 "LSCS" 3 "SB" 4 "STOP" 5 "SVD" 6 "Spab" 7 "Ectopic"
label values delivery1 delivery1
numlabel, add mask("#",)
tab delivery1
drop delivery
rename delivery1 delivery

* preg_success=.
gen preg_success=.
replace preg_success=1 if gest>=24 & gest<.
replace preg_success=0 if gest<24
replace preg_success=0 if BW<0.5
tab preg_success, miss


**pregnancy success (viable pregnancy): >=24 weeks gestation and birthweight >=0.5
gen preg_success1=0
replace preg_success1=1 if gest>=24 & gest<. & BW>0.5 & BW<.
replace preg_success1=. if BW==. | gest==.
tab preg_success1, miss

*menarche before and after mean
codebook agem
gen menarche_med=.
replace menarche_med =0 if agem <15.3
replace menarche_med=1 if agem >=15.3 & agem<.
label variable menarche_med "menarche>=median"
label define menarche_med 0 "below median" 1 "median or above"
label values menarche_med menarche_med

tab menarche_med, miss
tab menarche_med preg_success, col

/****delivery success

outcome of |
  pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
     1 ,CCS |          2        1.13        1.13 (successful)
    2 ,LSCS |         29       16.38       17.51 (sucessful)
      3 ,SB |         14        7.91       25.42 (unsuccessful)
    4 ,STOP |         14        7.91       33.33 (unsuccessful)
     5 ,SVD |         62       35.03       68.36 (successful)
    6 ,Spab |         56       31.64      100.00 (unsuccessful)
------------+-----------------------------------
      Total |        177      100.00											*/

gen del_success=.
replace del_success=0 if delivery==3 | delivery==4 |  delivery==6
replace del_success=1 if delivery==1 | delivery==2 | delivery==5
tab del_success, miss
label variable del_success "successful delivery"
label define del_success 0 "unsuccessful" 1 "successful"
label values del_success del_success
order del_success, after(delivery)
list delivery del_success preg_success BW gest if del_success != preg_success

*birthweight: low BW defined as <2.5kg
gen bw_cat=.
replace bw_cat=0 if BW<2.5
replace bw_cat=1 if BW>=2.5 & BW<.
label variable bw_cat "birthweight category"
label define bw_cat 0 "<2.5" 1 ">=2.5"
label values bw_cat bw_cat
tab bw_cat, miss

*prematurity
gen premat=.
replace premat=0 if preg_success==1 & gest>=37 & gest<.
replace premat=1 if preg_success==1 & gest<37
label variable premat "premature birth"
label define premat 0 "not premature" 1 "premature"
label values premat premat
tab premat, miss
list ID if del_success==1 & gest==.
tab premat if preg_success==1, miss

*low APGAR (defined as <7 at 5minutes)
gen lowAPGAR5=0
replace lowAPGAR5=1 if Apg5<7
replace lowAPGAR5=. if Apg5==.
tab preg_success lowAPGAR5
list ID Apg5 delivery if preg_success==0 &  lowAPGAR5==2
tab lowAPGAR5 if preg_success==1, miss
label define lowAPGAR5 0 "Apg5>=7" 1 "Apg5<7"
label values lowAPGAR5 lowAPGAR5

**length of labour if delivery was SVD
destring labourh, gen (lab)
gen labtime = lab*60
label var labtime "Labour time in minutes"
codebook labtime
summarize labtime
list labtime delivery if labtime!=. & delivery !=5
codebook labtime if delivery==5
summarize labtime if delivery==5

save "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\cohort_SSpreg.dta", replace


** comparison of characteristics of SS with matched controls vs not (31-Aug-2020; birth weight, live pregnancies, and admissions for bone pain and ACS)
sort Coh
gen match=0
order match, after(DOB)
replace match=1 if Coh>125 & match<.
*BW
tab bw_cat match, chi2 col 
*live birth
gen preg_out=.
replace preg_out=1 if delivery==1 | delivery==2 | delivery==5
replace preg_out=2 if delivery==3
replace preg_out=3 if delivery==4
replace preg_out=4 if delivery==6
replace preg_out=5 if delivery==7
label define preg_out 1 "Live birth" 2 "Stillbirth" 3 "Surgical termination of pregnancy" 4 "Spontaneous abortion" 5 "Ectopic"
label values preg_out preg_out
gen lbirth=.
replace lbirth=1 if preg_out==1
replace lbirth=0 if preg_out==2 | preg_out==3 | preg_out==4 | preg_out==5
label variable lbirth "live birth"
label define yesno 1 "Yes" 0 "No"
label values lbirth yesno
tab lbirth match, chi2 col

*Acute chest syndrome
tab ACS match, chi2 col 

*painful crisis
tab pcrisis match, chi2 col 


*****************************************************************************************************************
*	AA analysis
*****************************************************************************************************************
clear
**Open dataset
import excel "`datapath'\version01\1-input\Cohort AA pregnancy 2018 coding Ian-Christina(USE) (2).xlsx", sheet("Sheet1") firstrow clear
*------------------------------------------------------------------------------------------------------------------------------
**DATA PREPARATION
*------------------------------------------------------------------------------------------------------------------------------
drop if ID==.
drop if preg=="3a" | preg=="3b"
destring preg, replace
drop if preg==.
codebook ID
sort ID preg
drop Name Hosp EDD EDDd EDDm EDDy time blloss Notes
gen genotype=0
label define genotype 0 "AA" 1 "SS"
label values genotype genotype
rename preg pregtot
label variable pregtot "number of pregnancies"
label variable Coh "cohort #"
label variable DOB "date of birth"
label variable date "date of status assessment"
label variable age "age at assessment"
label variable menarche "date at menarche"
rename J agem
label variable agem "age at menarche"
label variable LMP "date of last menstrual period"
label variable LMPd "day of last mentrual period"
label variable LMPm "month of last menstrual period"
rename deliv dode1
label variable dode1 "date of pregnancy termination"
label variable DELd "day of pregnancy termination"
label variable DELm "month of pregnancy termination"
label variable DELy "year of pregnancy termination"
rename GA gest
label variable gest "gestational age"
label variable result "outcome of pregnancy"
label variable labourh "duration of labour"
*removing text entries from labourh
replace labourh = "" in 27
replace labourh = "" in 38
replace labourh = "" in 57
replace labourh = "" in 58
replace labourh = "" in 61
replace labourh = "" in 65
replace labourh = "" in 72
replace labourh = "" in 73
replace labourh = "" in 74
replace labourh = "" in 78
replace labourh = "" in 81
replace labourh = "" in 97
replace labourh = "" in 98
replace labourh = "" in 116
replace labourh = "" in 120
replace labourh = "" in 121
replace labourh = "" in 122
replace labourh = "" in 123
replace labourh = "" in 124
replace labourh = "" in 128
replace labourh = "" in 172
replace labourh = "" in 174
replace labourh = "" in 176
replace labourh = "" in 177
replace labourh = "" in 183
replace labourh = "" in 184
replace labourh = "" in 190
replace labourh = "" in 191
replace labourh = "" in 193
replace labourh = "" in 196
replace labourh = "" in 217
replace labourh = "" in 221
replace labourh = "" in 224
replace labourh = "" in 225
destring labourh, replace
rename indic Indic
label variable Indic "Indications for STOP, LSCS"
label variable sx "gender of child"
label variable BW "birthweight"
label variable Apg1 "Apgar 1 minute"
label variable Apg5 "Apgar at 5 minutes"
label variable ANC "visits to antenatal clinic"
		replace ANC = "" in 155
		replace ANC = "" in 165
		replace ANC = "" in 170
		replace ANC = "" in 171
		replace ANC = "" in 177
		replace ANC = "" in 189
		replace ANC = "" in 195
		replace ANC = "" in 196
		replace ANC = "" in 202
		replace ANC = "" in 203
		replace ANC = "" in 221
		replace ANC = "" in 222
		replace ANC = "" in 224
		replace ANC = "" in 225
rename compl complic
label variable complic "complications at delivery"

*split complic into separate components
split complic, p(,)
order complic, before(complic1)

forval x=1(1)2 {
	destring complic`x', replace
}

forval x=1(1)24 {
	gen comp`x'=0
	replace comp`x'=1 if complic1==`x' | complic2==`x'
	}
drop complic1 complic2

rename comp1 PPH
label variable PPH "post-partum haemorrhage"
rename comp2 shir
label variable shir "Shirodkar"
rename comp3 PIH
label variable PIH "pregnancy-induced HTN"
rename comp4 retplac
label variable retplac "retained placenta"
rename comp5 PET
label variable PET "pre-eclampsia"
rename comp6 UTI
rename comp7 cdef
label variable cdef "congenital deformity"
rename comp8 APH
label variable APH "antepartum haemorrhage"
rename comp9 ectp
label variable ectp "ectopic pregnancy"
rename comp10 ACS
label variable ACS "acute chest syndrome"
rename comp11 anaem
label variable anaem "severe anaemia"
rename comp12 breech
rename comp13 BBA
rename comp14 forcep
rename comp15 haemat
label variable haemat "haematoma"
rename comp16 pcrisis
label variable pcrisis "painful crisis"
rename comp17 adplac
label variable adplac "adherent placenta"
rename comp18 sep
label variable sep "sepsis"
rename comp19 DC
rename comp20 Death
label variable Death "Maternal death"
rename comp21 heps
label variable heps "hepatic sequestration"
rename comp22 CRF
rename comp23 SAH
rename comp24 jaun
label variable jaun "deep jaundice"

** AGE
bysort ID: replace DOB=DOB[1]
gen aap = (dode1 - DOB)/365.25
order aap, after(dode1)
label var aap "Age at pregnancy (in years)"

**age at menarche
codebook agem

**generate gravida based on gestational age
codebook gest
**remove non-numeric values from gestational age
replace gest = "" in 29
replace gest = "" in 30
replace gest = "" in 52
replace gest = "" in 53
replace gest = "" in 114
replace gest = "" in 117
replace gest = "" in 119
replace gest = "" in 120
replace gest = "" in 121
replace gest = "" in 122
replace gest = "" in 128
replace gest = "" in 145
replace gest = "" in 172
replace gest = "" in 176
replace gest = "" in 177
replace gest = "" in 224
replace gest = "" in 225
destring gest, replace

gen gravida1 =.
replace gravida1=1 if gest<.
bysort ID: egen gravida= sum(gravida1)
replace gravida=0 if gest==.
order gravida gravida1, after (pregtot)
drop gravida1
order gest, after (gravida)
codebook gravida
summarize gravida

**generating parity (defined as pregnancies >24 weeks regardless of outcome)
gen parity1=.
replace parity1=1 if gest<. & gest>24
bysort ID: egen parity=sum(parity1)
replace parity=0 if gest==.
drop parity1
order parity, after(gravida)
*histogram parity
codebook parity
summarize parity

**Pregnancy outcome (type of delivery) to be tidied up as follows:
tab result
/*  outcome of |
  pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
        Ect |          1        0.44        0.44
    Ectopic |          3        1.32        1.75
       LSCS |         31       13.60       15.35
         SB |          4        1.75       17.11
       STOP |         12        5.26       22.37
        SVD |        152       66.67       89.04
       Spab |         24       10.53       99.56
    ectopic |          1        0.44      100.00
------------+-----------------------------------
      Total |        228      100.00            */

encode result, gen(delivery)
order delivery, after(result)
numlabel, add mask("#",)
tab delivery

/*outcome of |
  pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
     1 ,Ect |          1        0.44        0.44
 2 ,Ectopic |          3        1.32        1.75
    3 ,LSCS |         31       13.60       15.35
      4 ,SB |          4        1.75       17.11
    5 ,STOP |         12        5.26       22.37
     6 ,SVD |        152       66.67       89.04
    7 ,Spab |         24       10.53       99.56
 8 ,ectopic |          1        0.44      100.00
------------+-----------------------------------
      Total |        228      100.00            */

recode delivery 2=1 8=1
tab delivery
/*outcome of |
 pregnancy |      Freq.     Percent        Cum.
------------+-----------------------------------
    1 ,Ect |          5        2.19        2.19
   3 ,LSCS |         31       13.60       15.79
     4 ,SB |          4        1.75       17.54
   5 ,STOP |         12        5.26       22.81
    6 ,SVD |        152       66.67       89.47
   7 ,Spab |         24       10.53      100.00
------------+-----------------------------------
     Total |        228      100.00           */

gen delivery1=.
replace delivery1=2 if delivery==3
replace delivery1=3 if delivery==4
replace delivery1=4 if delivery==5
replace delivery1=5 if delivery==6
replace delivery1=6 if delivery==7
replace delivery1=7 if delivery==1
label define delivery1 1 "CCS" 2 "LSCS" 3 "SB" 4 "STOP" 5 "SVD" 6 "Spab" 7 "Ectopic"
label values delivery1 delivery1
numlabel, add mask("#",)
tab delivery1
drop delivery
rename delivery1 delivery

****delivery success
**remove non numeric values of BW
replace BW = "" in 58
replace BW = "" in 101
replace BW = "" in 99
destring BW, replace

gen preg_success=.
replace preg_success=1 if gest>=24 & gest<.
replace preg_success=0 if gest<24
replace preg_success=0 if BW<0.5
tab preg_success, miss

**pregnancy success (viable pregnancy): >=24 weeks gestation and birthweight >=0.5
gen preg_success1=0
replace preg_success1=1 if gest>=24 & gest<. & BW>0.5 & BW<.
replace preg_success1=. if BW==. | gest==.
tab preg_success1, miss

*menarche before and after mean
codebook agem
gen menarche_med=.
replace menarche_med =0 if agem <15.3
replace menarche_med=1 if agem >=15.3 & agem<.
label variable menarche_med "menarche>=median"
label define menarche_med 0 "below median" 1 "median or above"
label values menarche_med menarche_med

tab menarche_med, miss
tab menarche_med preg_success, col

****delivery success
gen del_success=.
replace del_success=0 if delivery==3 | delivery==4 |  delivery==6 | delivery==7
replace del_success=1 if delivery==1 | delivery==2 | delivery==5
tab del_success, miss
label variable del_success "successful delivery"
label define del_success 0 "unsuccessful" 1 "successful"
label values del_success del_success
order del_success, after(delivery)
list delivery del_success preg_success BW gest if del_success != preg_success

*birthweight: low BW defined as <2.5kg
gen bw_cat=.
replace bw_cat=1 if BW<2.5
replace bw_cat=0 if BW>=2.5 & BW<.
label variable bw_cat "birthweight category"
label define bw_cat 1 "<2.5" 0 ">=2.5"
label values bw_cat bw_cat
tab bw_cat, miss

*prematurity
gen premat=.
replace premat=0 if preg_success==1 & gest>=37 & gest<.
replace premat=1 if preg_success==1 & gest<37
label variable premat "premature birth"
label define premat 0 "not premature" 1 "premature"
label values premat premat
tab premat, miss
list ID if del_success==1 & gest==.
tab premat if preg_success==1, miss

*low APGAR (defined as <7 at 5minutes)
**remove non-numeric values from Apg5
replace Apg5 = "" in 4
replace Apg5 = "" in 66
replace Apg5 = "" in 69
replace Apg5 = "" in 176
replace Apg5 = "" in 178
replace Apg5 = "" in 183
replace Apg5 = "" in 184
replace Apg5 = "" in 196
destring Apg5, replace
gen lowAPGAR5=0
replace lowAPGAR5=1 if Apg5<7
replace lowAPGAR5=. if Apg5==.
tab preg_success lowAPGAR5
list ID Apg5 delivery if preg_success==0 &  lowAPGAR5==2
tab lowAPGAR5 if preg_success==1, miss

**length of labour if delivery was SVD
gen labtime = labourh*60
label var labtime "Labour time in minutes"
codebook labtime
summarize labtime
list labtime delivery if labtime!=. & delivery !=5
codebook labtime if delivery==5
summarize labtime if delivery==5


save "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\cohort_AApreg.dta", replace

*****************************************************************************************************************
*	Combine datasets for SS AA comparison
*****************************************************************************************************************
append using "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\cohort_SSpreg.dta", force
tab genotype
order genotype, after(ID)
drop children

**************************************************************************************
*	Table 1: Selected characteristics and pregnancy outcomes of subjects and controls
**************************************************************************************
**set mother as cluster unit
xtset ID

*sort out outcome
	replace outcome = "live" in 186
	replace outcome = "" in 231
	replace outcome = "" in 234
	replace outcome = "NND" in 361
	replace outcome = "NND" in 379
	replace outcome = "live" in 398
	encode outcome, generate(outcome2)
	drop outcome
	rename outcome2 outcome	
	tab outcome genotype, chi2

**age at menarche
codebook agem if genotype==1
codebook agem if genotype==0
ranksum agem, by(genotype)

**SECTION 1: GRAVIDA AND PARITY
*histogram gravida, by(genotype)
summarize gravida if genotype==1
summarize gravida if genotype==0
ranksum gravida, by(genotype)

*histogram parity, by(genotype)
summarize parity if genotype==1
summarize parity if genotype==0
ranksum parity, by(genotype)

**SECTION 2: PREGNANCY OUTCOME 
**dropping one twin pregnancy from AA controls, as twin pregnancies change many of the features associated with pregnancy outcome.
drop if ID==1256 & pregtot==3
*Pregnancy outcome
tab delivery genotype, col

/*
           |       genotype
  delivery |     0 ,AA      1 ,SS |     Total
-----------+----------------------+----------
    1 ,CCS |         0          2 |         2    classical caesarian section
           |      0.00       1.13 |      0.49
-----------+----------------------+----------
   2 ,LSCS |        31         29 |        60 	 lower segment caesarian section
           |     13.72      16.38 |     14.81
-----------+----------------------+----------
     3 ,SB |         4         14 |        18    stillbirth
           |      1.77       7.91 |      4.44
-----------+----------------------+----------
   4 ,STOP |        12         14 |        26    Surgical Termination of pregnancy
           |      5.31       7.91 |      6.42
-----------+----------------------+----------
    5 ,SVD |       150         62 |       214    spontaneous vaginal delivery
           |     66.37      35.03 |     52.84
-----------+----------------------+----------
   6 ,Spab |        24         56 |        80    Spontaneous Abortion
           |     10.62      31.64 |     19.75
-----------+----------------------+----------
7 ,Ectopic |         5          0 |         5     Ectopic pregnancy
           |      2.21       0.00 |      1.23
-----------+----------------------+----------
     Total |       226        177 |       405
           |    100.00     100.00 |    100.00   */



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
xtlogit term genotype, or
xtgee term genotype aap, family(binomial) link(log) corr(exchangeable) eform

*spontaneous Abortion
gen spab=0 
replace spab=1 if delivery==6
replace spab=. if delivery==.
tab spab genotype, chi2 col
xtlogit spab genotype, or
xtgee spab genotype aap, family(binomial) link(log) corr(exchangeable) eform

 
*stillbirth - generate binary variable
gen sbirth=.
replace sbirth=1 if preg_out==2
replace sbirth=0 if preg_out==1 | preg_out==3 | preg_out==4 | preg_out==5
label variable sbirth "stillbirth"
label values sbirth yesno
xtlogit sbirth genotype, or
tab sbirth genotype, col chi exact
xtgee sbirth genotype aap, family(binomial) link(log) corr(exchangeable) eform


*ectopic pregnancy
tab ect genotype, chi2 exact col
xtlogit ect genotype, or



*live birth - generate binary variable
gen lbirth=.
replace lbirth=1 if preg_out==1
replace lbirth=0 if preg_out==2 | preg_out==3 | preg_out==4 | preg_out==5
label variable lbirth "live birth"
label define yesno 1 "Yes" 0 "No"
label values lbirth yesno
tab lbirth genotype, chi2 col
xtlogit lbirth genotype, or
xtgee lbirth genotype aap, family(binomial) link(log) corr(exchangeable) eform



*gestational age
codebook gest if genotype==1
codebook gest if genotype==0
ranksum gest, by(genotype)
gen lowgest=.
replace lowgest=1 if gest >= 24 & gest < 37 
replace lowgest=0 if gest>=37 & gest <.
replace lowgest=. if lbirth!=1
tab lowgest genotype, col
xtlogit lowgest genotype, or
xtgee lowgest genotype aap, family(binomial) link(log) corr(exchangeable) eform


*birthweight
replace BW=. if lbirth!=1
codebook BW if genotype==1
codebook BW if genotype==0
ranksum BW, by(genotype)
tab bw_cat genotype, col
xtlogit bw_cat genotype, or
*birthweight after controlling for gestational age
bysort genotype: sum BW
regress BW genotype
regress BW genotype gest

*low Apgar 
numlabel, add mask("#")
label values lowAPGAR5 lowAPGAR5
replace lowAPGAR5=. if lbirth==0
*replace lowAPGAR5=. if nnd==1
tab lowAPGAR5 genotype, col chi exact
logistic lowAPGAR5 genotype
xtlogit lowAPGAR5 genotype, or
xtgee lowAPGAR5 genotype aap, family(binomial) link(log) corr(exchangeable) eform


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
xtlogit ces genotype, or
xtgee ces genotype aap, family(binomial) link(log) corr(exchangeable) eform


*Acute chest syndrome
tab ACS genotype, chi2 exact
xtlogit ACS genotype, or
xtgee ACS genotype aap, family(binomial) link(log) corr(exchangeable) eform


*UTI
tab UTI genotype, col chi2 exact
xtlogit UTI genotype, or
xtgee UTI genotype aap, family(binomial) link(log) corr(exchangeable) eform


*Antepartum haemorrhage
tab APH genotype, chi2 exact
xtlogit APH genotype, or
xtgee APH genotype aap, family(binomial) link(log) corr(exchangeable) eform

*Post partum haemorrhage
tab PPH genotype, chi2 exact
xtlogit PPH genotype, or
xtgee PPH genotype aap, family(binomial) link(log) corr(exchangeable) eform


*Pregnancy induced hypertension
tab PIH genotype, col
xtlogit PIH genotype, or
xtgee PIH genotype aap, family(binomial) link(log) corr(exchangeable) eform

*Pre-eclampsia & eclampsia
tab PET genotype, chi2 exact expected col
xtlogit PET genotype, or
xtgee PET genotype aap, family(binomial) link(log) corr(exchangeable) eform

*Retained placenta
tab retplac genotype, chi2 exact col
xtlogit retplac genotype, or
xtgee retplac genotype aap, family(binomial) link(log) corr(exchangeable) eform


*sepsis
tab sep genotype, chi2 exact col

*maternal deaths
tab Death genotype, chi2 exact col



******************************************************************************************************************************************************
*  Added on 3rd May 2019 in response to IH's comments on draft of paper
******************************************************************************************************************************************************
*% with at least 1 ANC visit
replace ANC = "" in 86
replace ANC = "" in 90
replace ANC = "" in 147
replace ANC = "" in 158
replace ANC = "" in 159
replace ANC = "" in 21
replace ANC = "" in 27
replace ANC = "" in 56
replace ANC = "" in 57
replace ANC = "" in 59
replace ANC = "" in 63
replace ANC = "" in 64
replace ANC = "" in 65
replace ANC = "" in 66
replace ANC = "" in 74
replace ANC = "" in 76
replace ANC = "" in 78
replace ANC = "" in 81
replace ANC = "" in 97
replace ANC = "" in 98
replace ANC = "" in 114
replace ANC = "" in 118
replace ANC = "" in 121
replace ANC = "" in 122
replace ANC = "" in 123
replace ANC = "" in 128
replace ANC = "" in 136
replace ANC = "" in 139
replace ANC = "" in 160
replace ANC = "" in 193
replace ANC = "" in 226
replace ANC = "" in 259
replace ANC = "" in 263
replace ANC = "" in 352
replace ANC = "" in 370
replace ANC = "" in 373
replace ANC = "" in 107
destring ANC, replace
gen anc1=.
replace anc1=0 if ANC<1
replace anc1=1 if ANC>1 & ANC<.
replace anc1=. if gest<24
label variable anc1 "1+ ANC visits"
label define anc1 0 "no ANC visits" 1 "1+ ANC visits"
label values anc1 anc1
tab anc1 genotype, miss col
**4+ ANC visits
gen anc4=.
replace anc4=0 if ANC<4
replace anc4=1 if ANC>4 & ANC<.
replace anc4=. if gest<24
label variable anc4 "4+ ANC visits"
label define anc4 0 "<4 ANC visits" 1 "4+ ANC visits"
label values anc4 anc4 
tab anc4 genotype, miss col 


** Median gestational age in SS mothers in those with c section vs svd
codebook gest if ces==1 & genotype==1

gen svd=0
replace svd=1 if delivery==5
replace svd=. if delivery==.
codebook gest if svd==1 & genotype==1

***************************************************************************************************************************************************************
* CH check of all numbers in paper (7th Feb 2020)
***************************************************************************************************************************************************************
*page 6, line 1-3 
tabstat pregtot, statistics (n mean sd) by (genotype)
tabstat parity, statistics (n mean sd) by (genotype)
ranksum parity, by (genotype)
*page 6, lines 6-10
tab spab genotype, chi2 col
xtlogit spab genotype, or
*page 6, last paragraph
tab anc1 genotype, miss col
tab anc1 genotype, col
tab anc4 genotype, miss col
tab anc4 genotype, col

***************************************************************************************************************************************************************
* save dataset for further work
***************************************************************************************************************************************************************
save "X:\The University of the West Indies\DataGroup - repo_data\data_p130\version01\1-input\cohort_AASSpreg.dta", replace


/**Summarizing year of birth
gen year=year(DOB)
sort genotype DOB
gen num = _n
order num, after (DOB)
drop if num >298 // gets rid of cases with no matched controls

label variable DOB "Date of Birth"

#delimit ; 

graph box DOB, over (genotype) 
          box(1, fcolor(gs10) fintensity(inten100) lcolor(gs10)) medtype(cline) medline(lcolor(white) lwidth(medthick)) marker(1, mcolor(gs5) msize(small)) 
          title(Date of Birth in Cases and Controls) 
          xsize(3) graphregion(fcolor(white))
          ylabel(5000(200)5800, format (%td) angle(0) labsize(vsmall))
          ;
#delimit cr 

gen dup = 0
replace dup = 1 if ID==ID[_n+1]
order dup, after(ID)
drop if dup==1
tab year genotype

tabstat DOB, by(genotype) stat (p50 p25 p75) format(%td)

*****************************************************************************************************************************************************************
*	12-Mar-2019: total hemoglobin, mean cell volume, reticulocyte counts, total nucleated cell count, HbF level or alpha thalassaemia status; history of dactylitis 
******************************************************************************************************************************************************************
import excel "`datapath'\version01\1-input\Subdivisions pregnancy outcome.xlsx", sheet("christina") firstrow clear
drop if ID==.
merge 1:m ID using "`datapath'\version01\1-input\cohort_AASSpreg.dta"
drop if genotype==0
destring Group, replace
ologit Group Hb, or
ologit Group MCV, or
ologit Group retics, or
* don't think I have a  variable for total nucleated cell count
ologit Group HbF, or
ologit Group Alpha, or
ologit Group HOdactylitis, or 


****************************************************************************
**GS email (21-Mar-19): relationship between maternal HbF and birth weight
****************************************************************************
drop if genotype==0
bysort ID: egen HbF2 = min(HbF)
xtreg BW HbF2 
bysort ID: egen Hb2=min(Hb)
xtreg BW HbF2 Hb2 
bysort ID: egen retics2=min(retics)
xtreg BW HbF2 Hb2 retics2


*******************************************************
* Markov model: effect of pregnancy order on success 
*******************************************************
import excel using "`datapath'\version01\1-input\ss_preg_outcome_001.xlsx", firstrow clear

** Successful and unsuccessful pregnancy outcome
** Successful: SVD, LSCS
** Unsuccessful: SB, Spab, NND
label define op_ 0 "no" 1 "success"
foreach var in p1 p2 p3 p4 p5 p6 {
    gen o`var' = 0
    replace o`var' = 1 if `var' == "SVD" | `var' == "LSCS"
    replace o`var' = . if `var'==""
    label values  o`var' op_
}

** Pregnancies 1 to 6 as separate events
reshape long p op , i(pid) j(number)
xtset pid number

** Grouping pregnancies 3 and over
gen reduce35 = number
recode reduce35 4 5 6 = 3
gen op35 = op
replace op35 = op35[_n-1] if pid==pid[_n-1] & op35[_n-1]<. & number>=4
collapse (mean) op35, by(pid reduce35)

** Transition frequencies
** First and Second pregnancies
markov op35 if reduce35<=2
** Second and Third + pregnancies
markov op35 if reduce35>=2

** Modelling
xtset pid reduce35
xtlogit op35 i.reduce35, or

** xtlogit op35 reduce35, or
** predict pred35_1, pr
** xtlogit op35 i.reduce35, or
** predict pred35_2, pr