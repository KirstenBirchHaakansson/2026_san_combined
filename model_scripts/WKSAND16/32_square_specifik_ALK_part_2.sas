/**
*************************************************************************************
**************************************************************************************
*****             lgd age keys - surveys - v01 - lecage1.sas                  *****
*****      Analyses of age distributions using continuation-ratio logits         *****
**************************************************************************************
**************************************************************************************;

*/
*Input data til analysen
************************;
***Kun aldersprøver tages med***;
***Sted er med som gr_lv01, gr_lv02, intsq og PP_ar_tx (industriområder) ***;
***Alle fisk på 4 år og derover samles i en plusgruppe**;
*%include 'c:\ar\sas\sandeel\alk\hj_formats.sas';
*libname age_ssd 'c:\ar\sas\sandeel\ALK.';
*libname san 'c:\ar\sas\sandeel.';


* Changed for WKSANDEEL 2022 - added all (drop=_type_ _freq_) to all proc summary;
/*
%include 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples\hj_formats.sas';
libname age_ssd 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
libname san 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
*/

*%let year_working = 2022; *working / output year;
%let scenario = WKSAND16; *WKSAND16 / WKSAND22a / WKSAND22b;
%let update = 'partial'; *all|partial;
%let years_to_update_first = 2024;
%let years_to_update_last = 2025;

%let path_input = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\data;
%let path_model = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\model_scripts\WKSAND16;
%let output_folder = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\model;
%let path_output = &output_folder.\&scenario.;

%let path_ref = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\boot\data\references;

libname in "&path_input.";
libname out "&path_output.";

%include "&path_model\hj_formats.sas";


*Changed;
PROC IMPORT OUT= WORK.input_alk 
            DATAFILE= "&path_input./input_sas_alk.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 guessingrows=50000;
RUN;

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

proc sql;
create table tjek_data as
select distinct proj
from input_alk;

data input_alk;
set input_alk;
format month2 day2 $4.;

data_type = 'new';

if proj = 'NOR-sandeel' & aar < 2007 then delete; *Only import new data from 2007 - it was the time period being updated for WKSANDEEL 2022;

if proj = 'NOR-sandeel' then ctry = 'NOR';
else ctry = 'DNK';

month2 = month;
day2 = day;

drop month day;

run;

data input_alk;
set input_alk;

month = month2;
day = day2;

drop month2 day2;
run;

*Changed - explore missing NOR data - mark data to do so;

data norwegian_alk;
set in.norwegian_alk;

if aar > 2006 then delete;

ctry = 'NOR';
data_type = 'old';

run;

data incl_upd_dec18;
set in.incl_upd_dec18;

ctry = 'DNK';
data_type = 'old';

run;

data l1;
set input_alk norwegian_alk;  *Changed;
if art in ('TBK','NTB','TBT') then delete;
scm=floor(scm);
month_new = month*1; *Changed to allow for different input;
day_new = day*1; *Changed to allow for different input;
geartype='          ';
geartype='Commercial';
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

if aar gt 2000 and month_new in (11,12) then geartype='dredge';

if gear_type_txt in ('Box corer','Van Veen') then delete;
if PP_ar_tx='999' then PP_ar_tx='';
if month_new in (4,5,6) and day_new gt 15 then month_new=month_new+0.5; ***Disse måneder deles op i to**;
if month_new in (1,2) then month_new=1.5;
if month_new in (9,10) then month_new=9.5;
if month_new in (11,12) then month_new=11.5;
m=month_new*1;

************************Skift år her********************************;

*if aar lt 2017 then delete;
keep ctry aar intsq  gr_lv01 gr_lv02 geartype PP_ar_tx m month_new day_new data_type proj; *Added ctry to explore NOR data;
run;


* Added - output of included data;

proc sql;
create table out.tjek_data_input_alk_part2 as
select distinct aar, ctry, data_type, proj
from l1;

*Changed - explore missing NOR data;
proc sql;
create table out.tjek_nor_2 as
select distinct aar, ctry
from l1;

***********************************;

************************ New;
data l1;
set l1;

month = month_new;
day = day_new;

drop month_new day_new;

run;

****************************;
*****************Til square specifik alk med alle squares****************;

data l1b;
set l1;
if geartype ne 'Commercial' then delete;
drop gr_lv01 gr_lv02;
run;

proc sort data=l1b out=l2 nodupkey;
by geartype;
run;

data l3a;
set area;
geartype='          ';
geartype='Commercial';
run;

data l3b;
merge l2 l3a;
by geartype;
run;

data l3c;
set l3b;
intsq=square;
drop square;
run;

data l3d;
set l3c;

************************Skift år her********************************;

do aar=&years_to_update_first. to &years_to_update_last. by 1; *CHANGED;
output;
end;

run;

data l3e;
set l3d;
do m=1.5,3,4,4.5,5,5.5,6,6.5,7,8,9.5,11.5;
output;
end;
run;

data l3f;
set l3e;
do age=0 to 3 by 1;
output;
end;
run;

data l3g;
set l3f;
do scm=2 to 30 by 0.5;
output;
end;
run;

data l4;
set l3g;
 PP_ar_tx=put(intsq,$PPareasnew.);
if PP_ar_tx='999' then PP_ar_tx='';
if PP_ar_tx in ('1A','1B') then dobar='1A1B';
if PP_ar_tx in ('12C') then dobar='12C';
if PP_ar_tx in ('SH') then dobar='SH';
if PP_ar_tx in ('2A','6') then dobar='2A6';
if PP_ar_tx in ('3','2B') then dobar='2B3';
if PP_ar_tx in ('3AN','3AS') then dobar='3ANS';
if PP_ar_tx in ('4','5') then dobar='45';
if PP_ar_tx in ('1B','2B','12C','3','3AS','3AN') then NS='N';
if PP_ar_tx in ('1A','2A','4','5','6') then NS='S';
month=m;
month2='    ';
if month*1 in (1.5,3) then month2='1-3';
if month*1 in (4,4.5,5,5.5) then month2='4-5';
if month*1 in (6.5,6,7,8) then month2='6-8';
if month*1 in (9.5,11.5) then month2='9-12';
if month*1 in (1.5,3,4,4.5,5,5.5,6,6.5) then halfyear='1';
if month*1 in (7,8,9.5,11.5) then halfyear='2';
run;

***Nu tildeles en ALK fra det lavest mulige niveau****;

proc sort data=l4;
by aar intsq m geartype area PP_ar_tx age scm;
run;

data l83a;
set out.alk_level3;
m=month*1;
if geartype ne 'Commercial' then delete;
drop month;
run;

proc sort data=l83a out=l83 (drop=pi level);
by aar intsq m geartype area PP_ar_tx age scm;
run;

data l93;
merge l4 l83;
by aar intsq m geartype area PP_ar_tx age scm;
run;

data l103;
set l93;
level=3;
if age ne 0 and pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
pi=pred;
if pi=. then level=.;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;
proc sort data=l103;
by aar m geartype PP_ar_tx age scm;
run;

data l84a;
set out.alk_level4;
m=month*1;
if geartype ne 'Commercial' then delete;
drop month;
run;

proc sort data=l84a out=l84 (drop=pi level);
by aar m geartype PP_ar_tx age scm;
run;

data l94;
merge l103 l84;
by aar m geartype PP_ar_tx age scm;
run;

data l104;
set l94;
if pi=. and level=. then level=4;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

proc sort data=l104;
by aar m geartype dobar age scm;
run;

data l85a;
set out.alk_level5;
m=month*1;
if geartype ne 'Commercial' then delete;
drop month;
run;

proc sort data=l85a out=l85 (drop=pi level);
by aar m geartype dobar age scm;
run;

data l95;
merge l104 l85;
by aar m geartype dobar age scm;
run;

data l105;
set l95;
if pi=. and level=. then level=5;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

data l105b;
set l105;
if level=. then delete;
run;

proc sort data=l105;
by aar month2 geartype dobar age scm;
run;

proc sort data=out.alk_level6 out=l86 (drop=pi level);
by aar month2 geartype dobar age scm;
run;

data l96;
merge l105 l86;
by aar month2 geartype dobar age scm;
run;

data l106;
set l96;

if pi=. and level=. then level=6;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
if geartype ne 'Commercial' then delete;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

data l106b;
set l106;
if level=. then delete;
run;


proc sort data=l106;
by aar month2 geartype NS age scm;
run;

proc sort data=out.alk_level7 out=l87 (drop=pi level);
by aar month2 geartype NS age scm;
run;

data l97;
merge l106 l87;
by aar month2 geartype NS age scm;
run;

data l107;
set l97;
if pi=. and level=. then level=7;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
if geartype ne 'Commercial' then delete;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

proc sort data=l107;
by aar halfyear geartype NS age scm;
run;

proc sort data=out.alk_level8 out=l88 (drop=pi level);
by aar halfyear geartype NS age scm;
run;

data l98;
merge l107 l88;
by aar halfyear geartype NS age scm;
run;

data l108;
set l98;
*if aar=2017 and month in (5.5) and age=0 and dobar in ('1A1B') then pi=.;
*if aar=2017 and month in (5.5) and age=0 and dobar in ('1A1B') then level=.;

if pi=. and level=. then level=8;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
if geartype ne 'Commercial' then delete;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

proc sort data=l108;
by aar halfyear geartype age scm;
run;

proc sort data=out.alk_level9 out=l89 (drop=pi level);
by aar halfyear geartype age scm;
run;

data l99;
merge l108 l89;
by aar halfyear geartype age scm;
run;

data l109;
set l99;
if pi=. and level=. then level=9;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
if geartype ne 'Commercial' then delete;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

proc sort data=l109;
by aar  geartype age scm;
run;

proc sort data=out.alk_level10 out=l810 (drop=pi level);
by aar  geartype age scm;
run;

data l910;
merge l109 l810;
by aar  geartype age scm;
run;

data l110;
set l910;
if pi=. and level=. then level=10;
if pred ne . and maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then pred=0;
if pred ne . and maxscm ne . and maxscm=19 and scm gt maxscm+3 then pred=0;
if pred ne . and maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then pred=0;
if pred ne . and minscm ne . and minscm lt 20 and scm lt minscm-2 then pred=1;
if pred ne . and minscm ne . and minscm=22 and scm lt minscm-3 then pred=1;
if pred ne . and minscm ne . and minscm ge 24 and scm lt minscm-4 then pred=1;
if pi=. then pi=pred;
if pi=. then level=.;
if geartype ne 'Commercial' then delete;
drop _type_ _freq_ pred n s maxscm minscm lower upper minp maxp prange;
run;

data l11;
set l110;
if age=0 then pi0=pi;
if age=1 then pi1=pi;
if age=2 then pi2=pi;
if age=3 then pi3=pi;
if age=0 then l0=level;
if age=1 then l1=level;
if age=2 then l2=level;
if age=3 then l3=level;
if geartype ne 'Commercial' then delete;
run;

proc sort data=l11;
by aar intsq m  PP_ar_tx scm;
run;

proc summary data=l11;
var pi0-pi3 l0-l3;
by aar intsq m  PP_ar_tx scm;
output out=l12 (drop=_type_ _freq_) max=;
run;

*******  Unconditioned probabilities of being age 1, age 2, 3 and age 4+   ***********
*******  are calculated and plotted                                        ***********;

data l12b;
set l12;
do age=' 0',' 1',' 2',' 3',' 4';
output;
end;
run;

*****************Skift år her************;

data l13;
set l12b;
*if aar lt 2017 then delete;
if intsq='' then delete;
month=m;
if pi0=. and l0 in (8,9) and month in (1.5,3,4,4.5,5,5.5,6,6.5) then pi0=0;
if pi0=. and l0 in (.,10) and month in (1.5,3,4,4.5) then pi0=0;
if m lt 5 then pi0=0;
if aar in (1973,1986) then pi2=1;
if aar in (1973,1986)  then l2=10;
if aar in (1973,1986,1987,1991) then pi3=1;
if aar in (1973,1986,1987,1991) then l3=10;
if aar=1994 then pi0=0; 
if aar=1994 then l0=10; 
if aar=1996 and month in (1.5,3,4,4.5,5,5.5,6,6.5) then pi0=0;
if aar=1996 and month in (1.5,3,4,4.5,5,5.5,6,6.5) then l0=10;
if age=' 0' then p=pi0;
if age=' 1' then p=(1-pi0)*pi1;
if age=' 2' then p=(1-pi0-(1-pi0)*pi1)*pi2;
if age=' 3' then p=(1-pi0-(1-pi0)*pi1-(1-pi0-(1-pi0)*pi1)*pi2)*pi3;
if age=' 4' then p=(1-pi0-(1-pi0)*pi1-(1-pi0-(1-pi0)*pi1)*pi2-(1-pi0-(1-pi0)*pi1-(1-pi0-(1-pi0)*pi1)*pi2)*pi3);
keep aar intsq month  PP_ar_tx age p scm l0-l3 pi0-pi3;
run;

data l14;
set l13;
*if 1*month lt 7 then halfyear=1;
*if 1*month ge 7 then halfyear=2;

if age=' 0' then p0=p;
if age=' 1' then p1=p;
if age=' 2' then p2=p;
if age=' 3' then p3=p;
if age=' 4' then p4=p;
*if aar ne 1976 and aar ne 1977 then delete;
*if PP_ar_tx in ('SH','','999') then delete;
run;

proc sort data=l14;
by aar intsq month scm;
run;

proc summary data=l14;
var p0-p4 pi0-pi3 l0-l3;
by aar intsq month scm;
output out=l15 (drop=_type_ _freq_) max=;
run;

/*
data l16;

************************Skift år her********************************;

set out.alk17_square;
if aar gt 2016 then delete;
run;
*/

************************Skift år her********************************;

data out.alk18_square;
set l15; *l16;
if intsq='' then delete;
drop _type_ _freq_;
run;

title '';


data l14a;
set out.alk18_square;

************************Skift år her********************************;
*if aar not in (2010) then delete;
*if aar not in (1995, 2009, 2014, 2016, 2017,2018) then delete;
*if PP_ar_tx in ('') then delete;
*if month ne 5 then delete;
run;

proc sort data=l14a;
by aar month intsq scm;
run;

proc gplot data=l14a;
plot (p0 p1 p2 p3 p4)*scm/overlay haxis=axis1 vaxis=axis1;
by  aar month ;*PP_ar_tx ;
symbol1 v=plus value=star     height=0.3 cm i=join l=1 c=black;
symbol2 v=none value=circle   height=0.3 cm i=join l=1 c=red;
symbol3 v=none value=triangle height=0.3 cm i=join l=1 c=blue;
symbol4 v=none value=square   height=0.3 cm i=join l=1 c=orange;
symbol5 v=none value=plus     height=0.3 cm i=join l=1 c=purple;
symbol6 v=none value=triangle height=0.3 cm i=join l=1 c=yellow;
symbol7 v=none value=square   height=0.3 cm i=join l=1 c=green;
symbol8 v=none value=plus     height=0.3 cm i=join l=1 c=brown;
*title1 'plot of aglg19 - plot p*scm=age/overlay haxis=axis1 vaxis=axis1';
*title2 'by cruise surv_loc_new';

run;
quit;


*****************************************************************************************;
**************************************ALK slut ******************************************;
*****************************************************************************************;
/**/
