
**  DO-FILE METADATA
//  algorithm name				hbss_preg.do
//  project:							Pregnancy outcomes in SCD
//  analysts:							Christina HOWITT
//	date last modified		08-Jan-2019

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

*****************************************************************************************************************
*	AA analysis
*****************************************************************************************************************
clear
**Open dataset
import excel "`datapath'\version01\1-input\Cohort AA pregnancy 2018 coding Ian-Christina(USE).xlsx", sheet("Sheet1") firstrow clear

keep ID DOB status date menarche J preg deliv GA result labourh BW Apg5 outcome
drop if ID==.
codebook ID
sort ID preg
gen genotype=0
label define genotype 0 "AA" 1 "SS"
label values genotype genotype
**one participant has 3 IDs, so changing them to one
replace ID=1682 if ID==1683 | ID==1684
label variable DOB "date of birth"
rename preg pregtot
label variable pregtot "number of pregnancies"
rename J agem
label variable agem "age at menarche"
rename deliv dode1
label variable dode1 "date of pregnancy termination"
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
  replace labourh = "" in 99
  replace labourh = "" in 100
  replace labourh = "" in 118
  replace labourh = "" in 122
  replace labourh = "" in 123
  replace labourh = "" in 124
  replace labourh = "" in 125
  replace labourh = "" in 126
  replace labourh = "" in 130
  replace labourh = "" in 174
  replace labourh = "" in 176
  replace labourh = "" in 178
  replace labourh = "" in 179
  replace labourh = "" in 185
  replace labourh = "" in 186
  replace labourh = "" in 192
  replace labourh = "" in 193
  replace labourh = "" in 195
  replace labourh = "" in 198
  replace labourh = "" in 219
  replace labourh = "" in 223
  replace labourh = "" in 226
  replace labourh = "" in 227
label variable BW "birthweight"
label variable Apg5 "Apgar at 5 minutes"

********************************************************************************
*	Table 1: Selected characteristics and morbidity during pregnancy among 94
*	women with sickle cell disease
********************************************************************************

**********************CHARACTERISTICS OF WOMEN**********************************

**age at menarche
codebook agem

**generate gravida based on gestational age
codebook gest
**remove non-numeric values from gestational age
replace gest = "" in 29
replace gest = "" in 30
replace gest = "" in 116
replace gest = "" in 119
replace gest = "" in 121
replace gest = "" in 122
replace gest = "" in 123
replace gest = "" in 124
replace gest = "" in 130
replace gest = "" in 147
replace gest = "" in 174
replace gest = "" in 178
replace gest = "" in 179
replace gest = "" in 226
replace gest = "" in 227
replace gest = "" in 53
replace gest = "" in 52
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

*******************************************************************************************
* Table 2. Pregnancy outcomes for 174 pregnancies among 94 women with sickle cell disease *
*******************************************************************************************

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
**remove non-numeric values from Apg5
replace Apg5 = "" in 66
replace Apg5 = "" in 69
replace Apg5 = "" in 178
replace Apg5 = "" in 180
replace Apg5 = "" in 185
replace Apg5 = "" in 186
replace Apg5 = "" in 198
replace Apg5 = "" in 4
destring Apg5, replace
gen lowAPGAR5=0
replace lowAPGAR5=1 if Apg5<7
replace lowAPGAR5=. if Apg5==.
tab preg_success lowAPGAR5
list ID Apg5 delivery if preg_success==0 &  lowAPGAR5==2
tab lowAPGAR5 if preg_success==1, miss

**length of labour if delivery was SVD
destring labourh, gen (lab)
gen labtime = lab*60
label var labtime "Labour time in minutes"
codebook labtime
summarize labtime
list labtime delivery if labtime!=. & delivery !=5
codebook labtime if delivery==5
summarize labtime if delivery==5
