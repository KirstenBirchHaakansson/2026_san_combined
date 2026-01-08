/*
*************************************************************************************
**************************************************************************************
*****             length distributions                  *****
**************************************************************************************
**************************************************************************************;
/**/

* Changed for WKSANDEEL 2022 - added all (drop=_type_ _freq_) to all proc summary;
/*
%include 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples\hj_formats.sas';
libname age_ssd 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
libname san 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
*/

%let year_working = 2025; *working / output year;
%let scenario = WKSAND16; *WKSAND16 / WKSAND22a / WKSAND22b; *Area file;

%let update = 'partial'; *all|partial;

%let years_to_update_first = 2023;
%let years_to_update_last = 2024;

* New time series;
%let timeseries_start = 83;
%let timeseries_end = 24;

* Old time series;
%let old_timeseries_start = 83;
%let old_timeseries_end = 23;

%let include_old_time_series = 'yes'; *no|yes;

%let path_input = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\data;
%let path_model = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\model_scripts;
%let output_folder = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\model;
%let path_output = &output_folder.\&scenario.;

%let path_ref = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\boot\data\references;

libname in "&path_input.";
libname out "&path_output.";

%include "&path_model\hj_formats.sas";


*Changed;

PROC IMPORT OUT= WORK.area
            DATAFILE= "&path_ref./square_to_sandeel_areas_&scenario..csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 guessingrows=500;
RUN;

proc sort data = area;
by square;
run;

PROC IMPORT OUT= WORK.input_ld
            DATAFILE= "&path_input./input_sas_ld.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 guessingrows=50000;
RUN;

proc sql;
create table tjek_data as
select distinct cruise
from input_ld;

data input_ld;
set input_ld;
format month2 day2 $10.;

data_type = 'new';

if cruise = 'NOR-sandeel' & aar < 2007 then delete; *Only import new data from 2007 - it was the time period being updated for WKSANDEEL 2022;

if cruise = 'NOR-sandeel' then ctry = 'NOR';
else ctry = 'DNK';

month2 = month;
day2 = day;

drop month day;

run;

data input_ld;
set input_ld;

month = month2;
day = day2;

drop month2 day2;
run;

*Changed - explore  NOR data - mark data to do so;

data norwegian_length_freq;
set in.norwegian_length_freq;

ctry = 'NOR';
if aar > 2006 then delete;
data_type = 'old';

run;

data incl_upd_dec18;
set in.incl_upd_dec18;

ctry = 'DNK';
data_type = 'old';

run;


data l1;
set input_ld norwegian_length_freq; *Changed;
if art in ('TBK','NTB') then delete;

if spec_id=287211 then delete;***********tastet 2 gange en halv cm forskudt*******;
if spec_id=227737 then spec_id=227738; **delt ved en fejl*************************;
if spec_id in (287201,287213,287198,287210) then antal=antal/2;***********tastet 2 gange*******;
if spec_id in (287213) and scm=13 then antal=antal*2;***********ikke tastet 2 gange*******;
if spec_id in (287218) then st_antal=191;***********delt ved en fejl*******;
if spec_id in (287219) then st_antal=153;***********delt ved en fejl*******;
if spec_id in (287203) then st_antal=168;***********delt ved en fejl*******;
if spec_id in (287221) then st_antal=122;***********delt ved en fejl*******;
if spec_id in (287204) then st_antal=123;***********delt ved en fejl*******;
if spec_id in (287213) then st_antal=159;***********delt ved en fejl*******;

if usage_n in (1,5) then delete;

scm=floor(scm*2)/2;
if usage_txt in ('DIFRES database note indicate sample unusable, catch event',
'DIFRES database note indicate unreliable age determ', 
'DIFRES database note indicate unreliable species determ') then delete;

month_new = month*1; *Changed to allow for different input;
day_new = day*1; *Changed to allow for different input;

geartype='          ';
geartype='Commercial';

gr_lv01 = ' ';
gr_lv02 = ' ';

if gear_type_txt in ('Expo trawl') then geartype='survtrawl';
if cruise_cat in ('Sandeel survey  -DANA','Sandeel survey - DANA','IBTS','BITS','LIFECO',
'Havkat yngeltogt','Kattegat survey - Havfisken','Non sandeel non DANA scientific surveys',
'Non sandeel scientific DANA surveys','Sandeel survey - FRS')
then geartype='survtrawl';
if category='VID' and cruise ne 'Salling' then geartype='survtrawl';

if gear_type_txt in ('Danish sandeel dredge no. 1','Danish sandeel dredge no. 2',
'Danish sandeel dredge no. 3','Scottish sandeel dredge') then geartype='dredge';
if cruise_cat='Sandeel survey - commercial' then geartype='dredge';
if category='VID' and cruise='Salling' then geartype='dredge';

if aar gt 2000 and month_new in (11,12) then geartype='dredge'; *Changed; 

if gear_type_txt in ('Box corer','Van Veen') then delete;
if PP_ar_tx='999' then PP_ar_tx='';

if geartype ne 'Commercial' then delete;

if month_new in (4,5,6) and day gt 15 then month_new=month_new+0.5; ***Disse måneder deles op i to**;
if month_new in (1,2) then month_new=1.5;
if month_new in (9,10) then month_new=9.5;
if month_new in (11,12) then month_new=11.5; *Changed for 15 - spelling error;

if scm=. then delete;

vgt_dif_tot=(m_vgt-vgt_exp)/vgt_exp;

if vgt_dif_tot ne . and vgt_dif_tot lt -0.5 then vgt=.;
if vgt_dif_tot ne . and vgt_dif_tot lt -0.5 then m_vgt=.;
if vgt_dif_tot ne . and vgt_dif_tot gt 0.5 then m_vgt=.;
if vgt_dif_tot ne . and vgt_dif_tot gt 0.5 then vgt=.;
if vgt_exp=. then vgt=antal*m_vgt;
lnl=log(scm);
**************Prøver med få længdemålte fisk slettes******************;
if st_antal lt 25 then delete;

*****************Der er prøver uden angivelse af square***********************;
*****************De ryger ud som udgangspunkt*********************************;
if intsq='' then delete;

square='    ';
square=intsq;
if antal=. then delete;
drop intsq area month day;

if &update. = 'all' then do;
 output;
end;
if &update. = 'partial' then do;
	if aar <  &years_to_update_first. then delete;
	if aar >  &years_to_update_last. then delete;
	output;
end;


run;


************************ New;

proc sql;
create table out.tjek_data_input_ld as
select distinct aar, ctry, data_type, cruise
from l1;

data l1;
set l1;

month = month_new;
day = day_new;

drop month_new day_new;

run;

*Changed - Check month in input;

proc sql;
create table tjek_month as
select distinct month from l1;

*********************************;

*Changed - explore missing NOR data;
proc sql;
create table tjek_nor as
select distinct aar, ctry
from l1;

***********************************;

proc sort data=l1;
by square;
run;

*proc gplot data=l1;
*plot m_vgt*lnl;
*by aar;
*symbol v=plus i=none;
*run;



*****************Antal prøver pr square pr. month******************************************;

proc sort data=l1 out=l2 nodupkey;
by geartype aar month square day gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal;
run;

data l3;
set l2;
if month in (4.5,5.5,6.5) then month=floor(month);
run;

proc sort data=l3;
by aar month square;
run;

proc summary data=l3;
var antal;
by aar month square;
output out=l4 (drop=_type_ _freq_) n()=n_samples;
run;

data out.n_samples;
set l4;
run;


*Changed - Check month in input;

proc sql;
create table tjek_month_2 as
select distinct month from out.n_samples;

*********************************;

proc sort data=l4;
by square aar month ;
run;

proc sort data=area;
by square;
run;

data a1;
merge l4 area;
by square;
run;

proc sort data=a1;
by area aar ;
run;

proc summary data=a1;
var n_samples;
by area aar;
output out=a2 (drop=_type_ _freq_) sum()=n_samples;
run;

data out.n_samples_for_test;
set a2;
run;

****************Længdefordeling pr. prøve******************************************;
proc sort data=l1 out=l5;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
 scm vgt_exp;
run;


proc summary data=l5;
var antal vgt;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
scm vgt_exp;
output out=l6 (drop=_type_ _freq_) sum()=;
run;

/*
proc sort data=l1 out=l5;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
category vgt0 vgt1 l_vgt scm vgt_exp;
run;


proc summary data=l5;
var antal vgt;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
category vgt0 vgt1 l_vgt scm vgt_exp;
output out=l6 (drop=_type_ _freq_) sum()=;
run;
*/

data l5a;
set l6;
vgt_e_tot=vgt_exp*antal;
lnl=log(scm);
m_vgt=vgt/antal;
ln_m_vgt=log(m_vgt);
run;

*proc gplot data=l5a;
*plot m_vgt*scm;
*by aar;
*symbol v=plus i=join;
*run;

*******Her tilføjes en fælles længde-vægte relation, da de norske prøver ikke er vejet*****;

proc sort data=l5a;
by month scm;
run;

proc genmod data=l5a;
class scm;
model m_vgt=lnl/dist=gamma link=log;
output out=l5f pred=pred2;
by month;
run;

proc sort data=l5f nodupkey;
by month scm;
run;

data l5e;
merge l5a l5f;
by month scm;
run;

data l5e1;
set l5e;
if pred2 ne . and m_vgt gt 1.5*pred2 then m_vgt=.;
if pred2 ne . and m_vgt lt 0.5*pred2 then m_vgt=.;
run;

proc sort data=l5e1;
by aar month scm;
run;

proc genmod data=l5e1;
class scm;
model m_vgt=lnl/dist=gamma link=log;
output out=l5b pred=pred upper=upper lower=lower;
by aar month;
run;

proc sort data=l5b out=l5d nodupkey;
by aar month scm pred;
run;

data l5h;
merge l5e1 l5d;
by aar month scm;
run;

data l7b;
set l5h;
if m_vgt=. then vgt=antal*pred;
if m_vgt=. then m_vgt=pred;

if pred2 ne . and m_vgt gt 1.5*pred2 then vgt=antal*pred2; *Changed;
if pred2 ne . and m_vgt lt 0.5*pred2 then vgt=antal*pred2;
if pred2 ne . and m_vgt gt 1.5*pred2 then m_vgt=pred2; *Changed;
if pred2 ne . and m_vgt lt 0.5*pred2 then m_vgt=pred2;

intsq='        ';
intsq=square;
m=1*month;
drop month;
run;

data l7;
set l7b;
month=m;
drop m;
run;

proc sort data=l7;
by aar intsq month scm;
run;


proc sort data=out.alk18_square;
by aar intsq month scm;
run;

*Changed - Check month in input;

proc sql;
create table tjek_month_alk as
select distinct month from out.alk18_square;

proc sql;
create table tjek_month_l7 as
select distinct month from l7;
*********************************;

data l8;
merge l7 out.alk18_square;
by aar intsq month scm;
run;

data l9a;
set l8;
if antal=. then delete;
run;

data l9;
set l9a;

if scm lt 4 then delete;

if p0 lt 0.000000000001 then p0=0;
if p1 lt 0.000000000001 then p1=0;
if p2 lt 0.000000000001 then p2=0;
if p3 lt 0.000000000001 then p3=0;
if p4 lt 0.000000000001 then p4=0;

n0=antal*p0;
n1=antal*p1;
n2=antal*p2;
n3=antal*p3;
n4=antal*p4;


nsum=n0+n1+n2+n3+n4;

w0=vgt*p0;
w1=vgt*p1;
w2=vgt*p2;
w3=vgt*p3;
w4=vgt*p4;

nl0=scm*n0;
nl1=scm*n1;
nl2=scm*n2;
nl3=scm*n3;
nl4=scm*n4;

**************************NYT********************;
drop _type_ _freq_;

*******************''''''NYT SLUT***************;
run;

proc sort data=l9;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
;
run;

proc summary data=l9;
var n0-n4 w0-w4 nl0-nl4 antal nsum vgt;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
;
output out=l10 (drop=_type_ _freq_) sum()=;
run;

/*
proc sort data=l9;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
category vgt0 vgt1 l_vgt ;
run;

proc summary data=l9;
var n0-n4 w0-w4 nl0-nl4 antal nsum vgt;
by aar month square gr_lv01 gr_lv02 stat trip cruise julday spec_id st_antal 
category vgt0 vgt1 l_vgt ;
output out=l10 (drop=_type_ _freq_) sum()=;
run;
*/
data l11a;
set l10;

if aar lt &years_to_update_first. then delete;

if nsum lt 25 then delete;
if (vgt*0.95) lt vgt0 lt (vgt*1.05) then vgt=vgt0; *Question - open | closed?;
if (vgt*0.95) lt vgt1 lt (vgt*1.05) then vgt=vgt1; *Question - open | closed?;
if n0 lt 0.000000000001 then n0=0;
if n1 lt 0.000000000001 then n1=0;
if n2 lt 0.000000000001 then n2=0;
if n3 lt 0.000000000001 then n3=0;
if n4 lt 0.000000000001 then n4=0;
n0_per_kg=n0/vgt;
n1_per_kg=n1/vgt;
n2_per_kg=n2/vgt;
n3_per_kg=n3/vgt;
n4_per_kg=n4/vgt;
*************NYT*****************************;

if n0_per_kg=0 then mw0=.;
if n1_per_kg=0 then mw1=.;
if n2_per_kg=0 then mw2=.;
if n3_per_kg=0 then mw3=.;
if n4_per_kg=0 then mw4=.;

if n0_per_kg ne 0 then mw0=(w0/n0)*n0_per_kg;
if n1_per_kg ne 0 then mw1=(w1/n1)*n1_per_kg;
if n2_per_kg ne 0 then mw2=(w2/n2)*n2_per_kg;
if n3_per_kg ne 0 then mw3=(w3/n3)*n3_per_kg;
if n4_per_kg ne 0 then mw4=(w4/n4)*n4_per_kg;

*************NYT SLUT************************;
ml0=nl0/n0;
ml1=nl1/n1;
ml2=nl2/n2;
ml3=nl3/n3;
ml4=nl4/n4;
m=month*1;
p0=n0_per_kg/(nsum/vgt);
p1=n1_per_kg/(nsum/vgt);
p2=n2_per_kg/(nsum/vgt);
p3=n3_per_kg/(nsum/vgt);
p4=n4_per_kg/(nsum/vgt);
PP_ar_tx=put(square,$PPareasnew.);
if PP_ar_tx in ('1A','1B') then dobar='1A1B';
if PP_ar_tx in ('12C') then dobar='12C';
if PP_ar_tx in ('SH') then dobar='SH';
if PP_ar_tx in ('2A','6') then dobar='2A6';
if PP_ar_tx in ('3','2B') then dobar='2B3';
if PP_ar_tx in ('3AN','3AS') then dobar='3ANS';
if PP_ar_tx in ('4','5') then dobar='45';
if PP_ar_tx in ('1B','2B','12C','3','3AS','3AN') then NS='N';
if PP_ar_tx in ('1A','2A','4','5','6') then NS='S';
month2='    ';
if month*1 in (1.5,3) then month2='1-3';
if month*1 in (4,4.5,5,5.5) then month2='4-5';
if month*1 in (6.5,6,7,8) then month2='6-8';
if month*1 in (9.5,11.5) then month2='9-12';
if month*1 in (1.5,3,4,4.5,5,5.5,6,6.5) then halfyear='1';
if month*1 in (7,8,9.5,11.5) then halfyear='2';
if month in (4.5,5.5,6.5) then month=floor(month);
run;

proc sort data=l11a;
by square;
run;

data l11b;
merge l11a area;
by square;
run;

***************************Fix af misrapportering, fjern i 2015********************************;
data l11;
set l11b;
if aar = 2015 and square in ('41F1','41F2','41F3','41F4') then area=1; *Changed;
run;

proc sort data=l11;
by aar m;
run;

proc gplot data=l11;
plot (p0 p1 p2 p3 p4)*m/overlay;
by aar;
run;

proc gplot data=l11;
plot (n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg)*m/overlay;
by aar;
symbol1 v=plus i=black;
symbol2 v=plus i=red;
symbol3 v=plus i=blue;
symbol4 v=plus i=green;
symbol5 v=plus i=purple;
run;

proc gplot data=l11;
plot (mw0 mw1 mw2 mw3 mw4)*m=aar;
by aar;
run;

proc gplot data=l11;
plot (ml0 ml1 ml2 ml3 ml4)*m/overlay;
by aar;
run;

proc gchart data=l11;
vbar mw0 mw1 mw2 mw3 mw4/subgroup=aar;
run;

****************Datasæt med en line pr square, måned og år******;

**************Skift år her***************************************;
***************************Fix af misrapportering, fjern i 2015********************************;
data l3a;
set area;
do aar=&years_to_update_first. to &years_to_update_last. by 1;;
output;
end;
if aar = 2015 and square in ('41F1','41F2','41F3','41F4') then area='1r'; *Changed;
run;

data l3b;
set l3a;
month=.;
do month=1.5,3,4,5,6,7,8,9.5,11.5;
output;
end;
run;

data l3c;
set l3b;
*******************NYT**************;
PP_ar_tx='   ';
********************NYT SLUT***************;
PP_ar_tx=put(square,$PPareasnew.);
if PP_ar_tx in ('1A','1B') then dobar='1A1B';
if PP_ar_tx in ('12C') then dobar='12C';
if PP_ar_tx in ('SH') then dobar='SH';
if PP_ar_tx in ('2A','6') then dobar='2A6';
if PP_ar_tx in ('3','2B') then dobar='2B3';
if PP_ar_tx in ('3AN','3AS') then dobar='3ANS';
if PP_ar_tx in ('4','5') then dobar='45';
if PP_ar_tx in ('1B','2B','12C','3','3AS','3AN') then NS='N';
if PP_ar_tx in ('1A','2A','4','5','6') then NS='S';
month2='    ';
if month*1 in (1.5,3) then month2='1-3';
if month*1 in (4,4.5,5,5.5) then month2='4-5';
if month*1 in (6.5,6,7,8) then month2='6-8';
if month*1 in (9.5,11.5) then month2='9-12';
if month*1 in (1.5,3,4,4.5,5,5.5,6,6.5) then halfyear='1';
if month*1 in (7,8,9.5,11.5) then halfyear='2';
run;


*************level 3*****************;

proc sort data=l11;
by aar month area square;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar month area square;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
level=3;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;

*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
drop _type_ _freq_ n0-n4 sn0-sn4 nsamples antal;
run;

proc sort data=l3c;
by aar month area square;
run;

data m1;
merge l13 l3c;
by aar month area square;
run;


*************level 4*****************;

proc sort data=l11;
by aar month area PP_ar_tx;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar month area PP_ar_tx;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=4;
*************NYT*****************************;
if n0_per_kg=0 then mw0=.;
if n1_per_kg=0 then mw1=.;
if n2_per_kg=0 then mw2=.;
if n3_per_kg=0 then mw3=.;
if n4_per_kg=0 then mw4=.;

if n0_per_kg ne 0 then mw0=mw0/n0_per_kg;
if n1_per_kg ne 0 then mw1=mw1/n1_per_kg;
if n2_per_kg ne 0 then mw2=mw2/n2_per_kg;
if n3_per_kg ne 0 then mw3=mw3/n3_per_kg;
if n4_per_kg ne 0 then mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;

newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m1;
by aar month area PP_ar_tx;
run;

data m2;
merge l13 m1;
by aar month area PP_ar_tx;
run;

data m3;
set m2;
if level=. then level=lnew;

if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;

*************level 5*****************;

proc sort data=l11;
by aar month area dobar;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar month area dobar;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=5;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m3;
by aar month area dobar;
run;

data m4;
merge l13 m3;
by aar month area dobar;
run;

data m5;
set m4;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;

*************level 6*****************;

proc sort data=l11;
by aar month2 area dobar;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar month2 area dobar;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=6;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m5;
by aar month2 area dobar;
run;

data m6;
merge l13 m5;
by aar month2 area dobar;
run;

data m7;
set m6;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;


*************level 7*****************;

proc sort data=l11;
by aar month2 area;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar month2 area;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=7;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m7;
by aar month2 area;
run;

data m8;
merge l13 m7;
by aar month2 area;
run;

data m9;
set m8;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;

*************level 8*****************;

proc sort data=l11;
by aar halfyear area;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar halfyear area;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=8;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m9;
by aar halfyear area;
run;

data m10;
merge l13 m9;
by aar halfyear area;
run;

data m11;
set m10;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;

*************level 9*****************;

proc sort data=l11;
by aar halfyear;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar halfyear;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=9;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;

if mw0 gt mw1 then mw0=.;
*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m11;
by aar halfyear;
run;

data m12;
merge l13 m11;
by aar halfyear;
run;

data m13;
set m12;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;

drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew;
run;


*************level 10*****************;

proc sort data=l11;
by aar;
run;

proc summary data=l11;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 antal;
by aar;
output out=l12 (drop=_type_ _freq_) mean()= n(antal)=nsamples sum(n0)=sn0 sum(n1)=sn1 sum(n2)=sn2 sum(n3)=sn3
sum(n4)=sn4;
run;

data l13;
set l12;
if nsamples lt 5 then delete;
lnew=10;
*************NYT*****************************;
mw0=mw0/n0_per_kg;
mw1=mw1/n1_per_kg;
mw2=mw2/n2_per_kg;
mw3=mw3/n3_per_kg;
mw4=mw4/n4_per_kg;
if mw0 gt mw1 then mw0=.;

*************NYT SLUT************************;
if sn0 lt 10 then mw0=.;
if sn0 lt 10 then ml0=.;
if sn1 lt 10 then mw1=.;
if sn1 lt 10 then ml1=.;
if sn2 lt 10 then mw2=.;
if sn2 lt 10 then ml2=.;
if sn3 lt 10 then mw3=.;
if sn3 lt 10 then ml3=.;
if sn4 lt 10 then mw4=.;
if sn4 lt 10 then ml4=.;
newn0=n0_per_kg;
newn1=n1_per_kg;
newn2=n2_per_kg;
newn3=n3_per_kg;
newn4=n4_per_kg;
newmw0=mw0;
newmw1=mw1;
newmw2=mw2;
newmw3=mw3;
newmw4=mw4;
newml0=ml0;
newml1=ml1;
newml2=ml2;
newml3=ml3;
newml4=ml4;
newp0=p0;
newp1=p1;
newp2=p2;
newp3=p3;
newp4=p4;
drop _type_ _freq_ nsamples n0_per_kg n1_per_kg n2_per_kg n3_per_kg 
n4_per_kg mw0-mw4 ml0-ml4 p0-p4 n0-n4 sn0-sn4 antal;
run;

proc sort data=m13;
by aar ;
run;

data m14;
merge l13 m13;
by aar;
run;

data m15;
set m14;
if level=. then level=lnew;
if n0_per_kg=. then n0_per_kg=newn0;
if n1_per_kg=. then n1_per_kg=newn1;
if n2_per_kg=. then n2_per_kg=newn2;
if n3_per_kg=. then n3_per_kg=newn3;
if n4_per_kg=. then n4_per_kg=newn4;
if mw0=. then mw0=newmw0;
if mw1=. then mw1=newmw1;
if mw2=. then mw2=newmw2;
if mw3=. then mw3=newmw3;
if mw4=. then mw4=newmw4;

if ml0=. then ml0=newml0;
if ml1=. then ml1=newml1;
if ml2=. then ml2=newml2;
if ml3=. then ml3=newml3;
if ml4=. then ml4=newml4;

if p0=. then p0=newp0;
if p1=. then p1=newp1;
if p2=. then p2=newp2;
if p3=. then p3=newp3;
if p4=. then p4=newp4;
if p1=. then level=.;
label            
		             p0     = 'p0 to p4: proportion by numbers of age 0 to 4'
		             n0_per_kg     = 'Numbers of age 0 to 4 per kg of TBS'
		             ml0     = 'ml0 to ml4: mean length in cm of age 0 to 4'
		             mw0     = 'mw0 to mw4: mean weight of age 0 to 4 in kg'
					 level   ='Aggregation level of length samples'
 ;
drop newn0-newn4 newmw0-newmw4 newml0-newml4 newp0-newp4 lnew halfyear ns month2 dobar pp_ar_tx
;
run;

proc sort data=m15;
by aar month square;
run;

data m16a;
set out.n_samples;
m=1*month;
*if aar lt 2017 then delete;
drop month;
run;

data m16;
set m16a;
month=m;
drop m;
run;

proc sort data=m16;
by aar month square;
run;

data m17;
merge m15 m16;
by aar month square;
run; 

*Changed - Check month in input;

proc sql;
create table tjek_month_m15 as
select distinct month from m15;

proc sql;
create table tjek_month_m16 as
select distinct month from m16;
*********************************;


data m17a;
set in.mean_weight_and_n_per_kg_&old_timeseries_start._&old_timeseries_end.;
if aar ge &years_to_update_first. then delete;
run;

data out.mean_weight_and_n_per_kg_&timeseries_start._&timeseries_end.;
set m17a m17;
if n_samples=. then n_samples=0;
if n1_per_kg=. then delete;
label            
		             n_samples     = 'Number of length samples taken in the square in the month';

run;

proc export data=out.mean_weight_and_n_per_kg_&timeseries_start._&timeseries_end.
   outfile="&path_output.\mean_weight_and_n_per_kg_&timeseries_start._&timeseries_end..csv"
   dbms=csv 
   replace;
run;

/*
*quit;
/*
proc sort data=out.mean_weight_and_n_per_kg_2018 out=m17;
by area aar month square;
run;

data m17a;
set m17;
if aar lt 2010 then delete;
run;

proc gchart data=m17a;
vbar mw0 mw1 mw2 mw3 mw4
n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg/subgroup=aar;
*by area;
run;

proc summary data=m17;
var n_samples;
by area aar;
output out=m18 (drop=_type_ _freq_) sum()=;
run;

proc print data=m18;
var area aar n_samples;
run;

proc summary data=m17;
var n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg;
by area aar;
output out=m18 (drop=_type_ _freq_) mean()=;
run;

proc print data=m18;
var area aar n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg;
run;

proc gplot data=m18;
plot (n0_per_kg n1_per_kg n2_per_kg n3_per_kg n4_per_kg)*aar/overlay;
by area;
symbol1 v=0 i=join;
symbol2 v=1 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;
run;


proc gplot data=m18;
plot (n1_per_kg n2_per_kg)*aar/overlay;
by area;
symbol1 v=1 i=join;
symbol2 v=2 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;
run;


proc gplot data=m18;
plot (n3_per_kg n4_per_kg)*aar/overlay;
by area;
symbol1 v=3 i=join;
symbol2 v=4 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;
run;
