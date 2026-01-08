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

%let scenario = WKSAND16; *WKSAND16 / WKSAND22a / WKSAND22b;
%let update = 'partial'; *all|partial;
%let years_to_update_first = 2023;
%let years_to_update_last = 2024;

%let path_input = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\data;
%let path_model = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\model_scripts;
%let output_folder = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\model;
%let path_output = &output_folder.\&scenario.;

%let path_ref = Q:\mynd\Assessement_discard_and_the_like\stock_coord_work\san\2025_san_combined\boot\data\references;

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

*******************************************************;

data in1;

************************Skift år her********************************;

set input_alk;* norwegian_alk; *Changed;
if a0 = . then a0 = 0; *Changed from here;
if a1 = . then a1 = 0;
if a2 = . then a2 = 0;
if a3 = . then a3 = 0;
if a4 = . then a4 = 0;
if a5 = . then a5 = 0;
if a6 = . then a6 = 0;
if a7 = . then a7 = 0;
if a8 = . then a8 = 0;
if a9 = . then a9 = 0;
if a10 = . then a10 = 0;
if a11 = . then a11 = 0; *Changed to here;
a4=a4+a5+a6+a7+a8+a9+a10+a11;
atot=a0+a1+a2+a3+a4;
if atot=0 then delete;
if atot=. then delete;
if art in ('TBK','NTB','TBT') then delete;
scm=floor((scm*2))/2;
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
square='    ';
square=intsq;

if aar=2017 and spec_id=741323 then delete;  *****Meget store 0-årige?***;
keep ctry aar scm intsq square month_new day_new gr_lv01 gr_lv02 a0 a1 a2 a3 a4 atot geartype
PP_ar_tx data_type proj; *Changed - added ctry;

run;

data in1;
set in1;
************************Skift år her********************************;
if &update. = 'all' then do;
 output;
end;
if &update. = 'partial' then do;
	if aar <  &years_to_update_first. then delete;
	if aar >  &years_to_update_last. then delete;
	output;
end;

run;

* Added - output of included data;

proc sql;
create table out.tjek_data_input_alk as
select distinct aar, ctry, data_type, proj
from in1;

proc sql;
create table out.tjek_data_input_alk_no_age as
select aar, ctry, data_type, proj, sum(a0+a1+a2+a3+a4) as no_age
from in1
group by aar, ctry, data_type, proj;

*Changed - explore missing NOR data;
proc sql;
create table tjek_nor as
select distinct aar, ctry
from in1;

***********************************;

************************ New;
data in1;
set in1;

month = month_new;
day = day_new;

drop month_new day_new;

run;

****************************;

************************ Testing month & day ***********************;

data test_month_day;
set in1;
if month in (4,5,6) and day le 15 then month_new=month;
if month in (3,7,8) then month_new=month;

if month in (4,5,6) and day gt 15 then month_new=month+0.5; ***Disse måneder deles op i to**;
if month in (1,2) then month_new=1.5;
if month in (9,10) then month_new=9.5;
if month in (11,12) then month_new=11.5;

run;

proc sql;
create table test_month_day_2 as
select distinct month, day, month_new
from test_month_day;

data test_month_day_filter;
set in1;

if month le 3 then mark = 'mark';

run;

proc sql;
create table test_month_day_filter_2 as
select distinct month, mark
from test_month_day_filter;

data test_month_day_filter_a;
set test_month_day;

if month_new le 3 then mark = 'mark';

run;

proc sql;
create table test_month_day_filter_a_2 as
select distinct month, month_new, mark
from test_month_day_filter_a;


********************************************************************;

proc sort data=in1 out=x2;
by aar;
run;

proc summary data= x2;
var a0 a1 a2 a3 a4;
by aar;
output out=x3 (drop = _type_ _freq_) sum()=;
run;

data x4;
set x3;
atot=(a0+a1+a2+a3+a4);
p0=a0/atot;
p1=a1/atot;
p2=a2/atot;
p3=a3/atot;
p4=a4/atot;
run;


proc gplot data=x4;
plot (a0-a4 p0-p4 atot)*aar;
run;


proc sort data=in1;
by square;
run;

proc sort data=area out=a1;
by square;
run;

data in1a;
merge in1 a1;
by square;
run;

*******  Input data contains the columns pos, aar, length, age, gear      ***********
*******  and no. This corresponds to position, aar, length in cm, age,    ***********
*******  a gear/lab effect and number of this age and length in the sample ***********
*******  Input data=in1                                                 ***********;


*To apply the method on the sandeel data, the conditional probability of being age 1 and 2 are examined in two seperate models.
*There has to be a line for each age, even when the number recorded is zero.
*These lines are therefore added by adding a dataset in which all ages (0, 1, 2, 3, 4+) are recorded with the number zero.
*Further, to calculate the conditional probabilities of being age 0, 1, 2 and 3, columns are added to sum the number of fish
*being of age 0, 1, 2, 3 or greater
********************************************************************************************************************************; 


*Input data til tobisanalyse på bankeniveau
*Data transposes
*******************************************;
 data aglg01; set in1a;
  
   drop a0-a4;

   age=0;  n_age=a0;  output aglg01;
   age=1;  n_age=a1;  output aglg01;
   age=2;  n_age=a2;  output aglg01;
   age=3;  n_age=a3;  output aglg01;
   age=4;  n_age=a4;  output aglg01;

run;

proc sort data=aglg01 out=iin;
by geartype aar intsq area PP_ar_tx month day  gr_lv01 gr_lv02 scm;
run;


proc sort data=iin (keep=geartype aar scm intsq area 
PP_ar_tx month day  gr_lv01 gr_lv02 age) out=aglg1 nodupkey;
by geartype aar intsq area PP_ar_tx month day  gr_lv01 gr_lv02 ;
run;

*Nulvaerdier for aldre genereres
********************************;
data aglg2a;
set aglg1;
do age=0,1,2,3,4;
output;
end;
run;


*Nulvaerdier inkluderes for længder der ikke findes i prøverne,
*så at der beregnes en p værdi for disse længder også (modellen ekstrapolseres)
*******************************************************************************;

data aglg2;
set aglg2a;
do scm=2 to 30 by 0.5;  
output;
end;
run;


data aglg3;
set aglg2;
n_age=0;
run;

*Data til fortsat logit genereres
*********************************;

data aglg4;
set iin aglg3;                *NB! både input datasæt=iin og totaglg datasæettet=aglg13 med nulværdier appendes;
n0=0;
n1=0;
n2=0;
n3=0;
n4=0;
if scm lt 6 then n_age=.;              *Fisk mindre end 6 cm laves der ikke ALK for*;
if age=0 then n0=n_age; *nx angiver antallet af fisk for den pågøldende længde der er alder x;
if age=1 then n1=n_age;
if age=2 then n2=n_age;
if age=3 then n3=n_age;
if age=4 then n4=n_age;
s0=0;
s1=0;
s2=0;
s3=0;
s4=0;
if age ge 0 then s0=n_age; *sx angiver antallet af fisk der er alder x og ældre;
if age ge 1 then s1=n_age;
if age ge 2 then s2=n_age;
if age ge 3 then s3=n_age;
if age ge 4 then s4=n_age;
if geartype='Non sandeel non DANA scientific surveys' then delete; **Kun data fra 1988 og 2002;
if geartype='Commercial harbour based sampling' then intsq='';
**range of observed lengths:
0: 3-18
1: 1-22
2: 2-26
3: 10-26
4: 7-26
***;
**if scm gt 20 then scm=2*floor(scm/2); *Over 10 cm bruges cm grupper i stedet for scm*;
if month in (4,5,6) and day gt 15 then month=month+0.5; ***Disse måneder deles op i to**;
if month in (1,2) then month=1.5;
if month in (9,10) then month=9.5;
if month in (11,12) then month=11.5;
if month le 3 then n0=0;  **0-årige i jan-mar slettes (de kunne også omdøbes til 1-årige)*;
keep geartype aar area PP_ar_tx 
intsq month day gr_lv01 gr_lv02 scm age n_age n0-n4 s0-s4;
run;

proc sort data=aglg4;
by geartype aar month intsq area PP_ar_tx gr_lv01 gr_lv02 scm;
run;


proc summary data=aglg4; *Prøver summeres pr. cruise gr_lv01 gr_lv02  scm - altså stationer sammenlægges;
var n0-n4 s0-s4;
by geartype aar month intsq area PP_ar_tx gr_lv01 gr_lv02  scm;
output out=out.aglg5a (drop = _type_ _freq_) sum()=;
run;


*******  Det følgende program kører på flere niveauer (se note-dokument)  ****;

%inc "&path_model\alk_level3.sas";
%inc "&path_model\alk_level4.sas";
%inc "&path_model\alk_level5.sas";
%inc "&path_model\alk_level6.sas";
%inc "&path_model\alk_level7.sas";
%inc "&path_model\alk_level8.sas";
%inc "&path_model\alk_level9.sas";
%inc "&path_model\alk_level10.sas";

****** Hvert kombination af plads, tid, geartype merges med level 1, hvis det ikke giver en 
pi-værdi, så med level 2 osv***;
****** Først laves en linie for hver kombination af sted, tid og type i databasen**;
end;
quit;
