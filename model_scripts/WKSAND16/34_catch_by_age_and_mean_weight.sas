/**/

* Changed for WKSANDEEL 2022 - added all (drop=_type_ _freq_) to all proc summary;
/*
%include 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples\hj_formats.sas';
libname age_ssd 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
libname san 'Q:\mynd\Assessement_discard_and_the_like\assessment_scripts\HAWG_sandeel\2022\WKSANDEEL\model\debugging\15_fix_n_samples';
*/
%let year_working = 2026; *working / output year;
%let scenario = WKSAND16; *WKSAND16 / WKSAND22a / WKSAND22b / NS;
%let update = 'partial'; *all|partial;

%let years_to_update_first = 2024;
%let years_to_update_last = 2025;
%let timeseries_start = 83;
%let timeseries_end = 25;

%let include_old_time_series = 'yes'; *no|yes;

%let path_input = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\data;
%let path_model = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\model_scripts\WKSAND16;
%let output_folder = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\model;
%let path_output = &output_folder.\&scenario.;

%let path_ref = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\boot\data\references;

libname in "&path_input.";
libname out "&path_output.";

%include "&path_model\hj_formats.sas";



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

PROC IMPORT OUT= WORK.input_catch_year_month_square
            DATAFILE= "&path_input./catch_year_ctry_month_square_99_&timeseries_end..csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 DELIMITER=';';
	 guessingrows=50000;
RUN;

proc sql;
create table tjek_month_new_square as
select distinct month from
input_catch_year_month_square;

************Der er to input data sæt: havret tilbage til 1989 og logbog fra 1982-1988******;

data c1;
set in.cpue_2017;
if year ge 1989 then delete;
ton=yield;
day=endday;
if day=. then day=stday+(st_date-end_date);
if day=. then day=stday+days;
if month in (1,3,5,8,10,12) and day gt 31 then month=month+1;
if month in (4,6,7,9,11) and day gt 30 then month=month+1;
if month in (2) and day gt 28 then month=month+1;

if month in (1,2) then month=1.5;
if month in (9,10) then month=9.5;
if month in (11,12) then month=11.5;
square=ices_txt;
run;

proc sort data=c1;
by year month square;
run;

proc summary data=c1;
var ton;
by year month square;
output out=c2 (drop=_type_ _freq_) sum()=ton;
run;

data c2a;
set c2;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';
run;

proc sort data=c2a;
by year PP_ar_tx;
run;

proc summary data=c2a;
var ton;
by year PP_ar_tx;
output out=c2aa (drop=_type_ _freq_) sum()=PP_ton;
run;

data c2ab;
merge c2a c2aa;
by year PP_ar_tx;
run;

data c2ac;
merge c2ab in.pop_area_catches;
by year;
run;

data c3;
set c2ac;
if PP_ar_tx='1A' then ton=1000*ton*pop1a/PP_ton;
if PP_ar_tx='1B' then ton=1000*ton*(pop1b*5/6)/PP_ton;
if PP_ar_tx='1C' then ton=1000*ton*(pop1c+pop2c)/PP_ton;
if PP_ar_tx='2A' then ton=1000*ton*pop2a/PP_ton;
if PP_ar_tx='2B' then ton=1000*ton*(pop1b/6+pop2b)/PP_ton;
if PP_ar_tx='3' then ton=1000*ton*pop3/PP_ton;
if PP_ar_tx='4' then ton=1000*ton*pop4/PP_ton;
if PP_ar_tx='5' then ton=1000*ton*pop5/PP_ton;
if PP_ar_tx='6' then ton=1000*ton*pop6/PP_ton;
if PP_ar_tx='SH' then ton=1000*ton*shetland/PP_ton;
if PP_ar_tx in ('999','') then delete;
keep year icesdiv ton month square;
 run;

**************************1989-1993****;

data cb1;
set in.Havr89_og_frem_alle_arter17aug10;
if art not in ('TBS','TBM','TBT') then delete;
month=md;
if month in (1,2) then month=1.5;
if month in (9,10) then month=9.5;
if month in (11,12) then month=11.5;
square=sq;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';
if ton=0 then delete;
year=aar;
if year ge 1994 then delete;
drop mon md sq frv farvkod kv area lg a b n3sq tbarea;
run;

proc sort data=cb1;
by ICESdiv year month square PP_ar_tx;
run;

proc summary data=cb1;
var ton;
by ICESdiv year month square PP_ar_tx;
output out=cb2 (drop=_type_ _freq_) sum()=;
run;

proc sort data=cb2;
by year PP_ar_tx;
run;

proc summary data=cb2;
var ton;
by year PP_ar_tx;
output out=cb2a (drop=_type_ _freq_) sum()=PP_ton;
run;

data cb2b;
merge cb2 cb2a;
by year PP_ar_tx;
run;

data cb2c;
merge cb2b in.pop_area_catches;
by year;
run;

data cb3;
set cb2c;
if PP_ar_tx='1A' then ton=1000*ton*pop1a/PP_ton;
if PP_ar_tx='1B' then ton=1000*ton*(pop1b*5/6)/PP_ton;
if PP_ar_tx='1C' then ton=1000*ton*(pop1c+pop2c)/PP_ton;
if PP_ar_tx='2A' then ton=1000*ton*pop2a/PP_ton;
if PP_ar_tx='2B' then ton=1000*ton*(pop1b/6+pop2b)/PP_ton;
if PP_ar_tx='3' then ton=1000*ton*pop3/PP_ton;
if PP_ar_tx='4' then ton=1000*ton*pop4/PP_ton;
if PP_ar_tx='5' then ton=1000*ton*pop5/PP_ton;
if PP_ar_tx='6' then ton=1000*ton*pop6/PP_ton;
if PP_ar_tx='SH' then ton=1000*ton*shetland/PP_ton;
if PP_ar_tx in ('999','') then delete;
keep year icesdiv ton  month square;
run;

*******************  1994-1998 **;

******************* Distribute non-DK catches on months according to DK catches**;

data i2;
set in.non_dk_landings_by_sq;
do year=1994 to 1998 by 1;
output;
end;
run;

data i3;
set i2;
if year=1994 then iton=_994;
if year=1995 then iton=_995;
if year=1996 then iton=_996;
if year=1997 then iton=_997;
if year=1998 then iton=_998;
if iton=. then iton=0;
if square in ('') then delete;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';
if square='Max' then delete;
keep square iton year icesdiv;
run;

data i4;
set i3;
m=.;
do m=1.5,3,4,5,6,7,8,9.5,11.5;
output;
end;
run;

proc sort data=i4;
by year icesdiv square m;
run;


*****Månedlig fordeling fra area for squares hvor der ikke er danske logbøger*****;

data i5;
set in.Havr89_og_frem_alle_arter17aug10;
if art not in ('TBS','TBM','TBT') then delete;
month=md;
if month in (1,2) then month=1.5;
if month in (9,10) then month=9.5;
if month in (11,12) then month=11.5;
square=sq;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';
if ton=0 then delete;
year=aar;
if year ge 1999 then delete;
if year lt 1994 then delete;
m=1*month;
drop mon md sq frv farvkod kv area lg a b n3sq tbarea;
run;

proc sort data=i5;
by year icesdiv square m;
run;

proc summary data=i5;
var ton;
by year icesdiv square m;
output out=i6 (drop=_type_ _freq_) sum()=;
run;

data t2;
merge i4 i6;
by year icesdiv square m;
run;

proc sort data=t2;
by year  m;
run;

proc summary data=t2;
var ton;
by year  m;
output out=t4 (drop=_type_ _freq_) sum()=tonmonth;
run;

proc summary data=t2;
var ton;
by year ;
output out=t5 (drop=_type_ _freq_) sum()=tonyear;
run;

data t6;
merge t2 t4;
by year  m;
run;

data t7;
merge t6 t5;
by year ;
run;

proc sort data=t7;
by year icesdiv square;
run;

proc summary data=t7;
var ton iton;
by year icesdiv square;
output out=t7a (drop=_type_ _freq_) sum(ton)=dktonsq max(iton)=itonsq;
run;

data t8;
merge t7 t7a;
by year icesdiv square;
run;

data t9;
set t8;
if iton=. then iton=0;
if ton=. then ton=0;
if ton=0 and iton=0 then delete;
if tonmonth=. then tonmonth=0;

intton=iton*ton/dktonsq;
if intton=. then intton=iton*tonmonth/tonyear;
iton=intton;
month=m;
keep year square icesdiv iton ton month;
run;
/*
***********************from 1999 onwards;
*********************Lav input til square fil fra Havret****************************;
data i4;
*********************Skift år her*******************;
set in.havr89_og_frem_alle_arter;
if art not in ('TBS','TBM','TBT') then delete;
month=md;
half_year=1;
if month ge 7 then half_year=2;
year=aar;
square=sq;
country='DEN';

if square in ('') then delete;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';

if year lt 1999 then delete;
run;

proc sort data=i4;
by year icesdiv square month;
run;

proc summary data=i4;
var ton;
by year icesdiv square month;
output out=i5 (drop=_type_ _freq_) sum()=weight;
run;


proc summary data=i4;
var ton;
by year icesdiv square;
output out=i5a (drop=_type_ _freq_) sum()=weight;
run;

data i5b;
set i5a;
tonF4=0;
if square in ('41F1','41F2','41F3','41F4') then tonF4=weight;
if square not in ('41F1','41F2','41F3','41F4','41F5') then delete;
run;

proc summary data=i5b;
var tonF4 weight;
by year icesdiv;
output out=i5c (drop=_type_ _freq_) sum()=;
run;

data i5d;
set i5c;
ratio=tonF4/weight;
run;

proc gplot data=i5d;
plot tonf4*(year weight);
run;

proc summary data=age_ssd.n_samples;
var n_samples;
by aar;
output out=x6 sum()=;
run;

*proc export data=i5
   outfile='e:\ar\tobis\catches\catch_year_month_square_denmark_2017.csv'
   dbms=csv 
   replace;
*run;
*quit;
*/
data i21;
set in.catch_year_month_square_2018;
ton=0;
iton=0;
if country='DEN' then ton=weight;
if country ne 'DEN' then iton=weight;
if square in ('') then delete;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';

if month in (1,2) then month=1.5; *Changed;
if month in (9,10) then month=9.5; *Changed;
if month in (11,12) then month=11.5; *Changed;

if aar > 2017 then delete;

keep square iton ton year icesdiv month country;
run;

data i22;
set input_catch_year_month_square;
ton=0;
iton=0;
*country = vesselFlagCountry;
*square = statisticalRectangle;
if country='DEN' then ton=weight;
if country ne 'DEN' then iton=weight;
if square in ('', 'NA') then delete;
PP_ar_tx='   ';
PP_ar_tx=put(square,$PPareas.);
ICESdiv='    ';
if PP_ar_tx in ('3AS','3AN') then ICESdiv='IIIa';
if PP_ar_tx in ('1A','1B','1C','2A','2B','2C','3','4','5','6','SH') then ICESdiv='IV';

if month in (1,2) then month=1.5; *Changed;
if month in (9,10) then month=9.5; *Changed;
if month in (11,12) then month=11.5; *Changed;

if year < 2018 then delete;

keep square iton ton year icesdiv month country;
run;

data i2; 
set i21 i22;
run;

data i2a;
set in.catch_year_month_square_2018;

* Add area to i2a and output;
proc sql;
create table lan_per_ctry_area as
select country, year, month, a.square, icesdiv, area, (ton+iton) as ton
from i2 a left join area b
on a.square = b.square;

proc export data=lan_per_ctry_area
   outfile="&path_output.\lan_per_ctry_year_month_div_area.csv"
   dbms=csv 
   replace;
run;
quit;


*Change - check month in square file;
*merge cb6 x3b - biology needs half months;

proc sql;
create table tjek_month as
select distinct month
from i2;

***********************************;

proc sort data=i2;
by year icesdiv country;
run;

proc summary data=i2;
var ton iton;
by year icesdiv country;
output out=i3b (drop=_type_ _freq_) sum()=;
run;

/*
proc export data=i3b
   outfile="&path_output.\official_catches_2023.csv"
   dbms=csv 
   replace;
run;
quit;
*/
proc sort data=i2;
by year icesdiv square month;
run;

proc summary data=i2;
var iton ton;
by year icesdiv square month;
output out=i3 (drop=_type_ _freq_) sum()=;
run;

proc summary data=i3;
var iton ton;
by year icesdiv square;
output out=x2 (drop=_type_ _freq_) sum()=;
run;

data x3;
set x2;
totton=iton+ton;
drop iton ton;
run;

proc export data=x3
   outfile="&path_output.\Total_catch_per_square_&years_to_update_last..csv"
   dbms=csv 
   replace;
run;
quit;


data i6;
merge i3 i5;
by year icesdiv square month;
run;

data t2;
set c3 cb3 t9 i3;
if iton=. then iton=0;
if ton=. then ton=0;
totton=ton+iton;
run;

proc sort data=t2;
by year icesdiv;
run;

proc summary data=t2;
var ton iton totton;
by year icesdiv;
output out=t4 (drop=_type_ _freq_) sum(ton)=dktondiv sum(iton)=itondiv sum(totton)=ttondiv;
run;

data t5;
merge t2 t4;
by year icesdiv;
run;

proc sort data=in.official_landings_3a;
by year;
run;

data t10;
merge t5 in.official_landings_3a;
by year;
run;

data t11;
set t10;
DKIIIa=denmark;
totIIIa=total;
drop denmark norway sweden faroe total; 
run;

data t12;
merge t11 in.official_landings_4abc;
by year;
run;

data t13;
set t12;
if ton=. and iton=. then delete;
if ton=0 and iton=. then delete;
if ton=0 and iton=0 then delete;
if year gt 1993 and iton=. then iton=0;

if year=2012 and icesdiv='IIIa' then totIIIa=1695;
if year=2012 and icesdiv='IIIa' then DKIIIa=1695;
if year=2012 and icesdiv='IV' then total=99904;
if year=2012 and icesdiv='IV' then denmark=50064;

if year=2013 and icesdiv='IIIa' then totIIIa=15956.6;
if year=2013 and icesdiv='IIIa' then DKIIIa=15956.6;
if year=2013 and icesdiv='IV' then total=262032;
if year=2013 and icesdiv='IV' then denmark=192729;


if year=2014 and icesdiv='IIIa' then totIIIa=8578.54;
if year=2014 and icesdiv='IIIa' then DKIIIa=8578.54;
if year=2014 and icesdiv='IV' then total=255183.85;
if year=2014 and icesdiv='IV' then denmark=147963;

if year=2015 and icesdiv='IIIa' then totIIIa=3321;
if year=2015 and icesdiv='IIIa' then DKIIIa=3321;
if year=2015 and icesdiv='IV' then total =308573;
if year=2015 and icesdiv='IV' then denmark=163178;

if year=2016 and icesdiv='IIIa' then totIIIa=1529;
if year=2016 and icesdiv='IIIa' then DKIIIa=1529;
if year=2016 and icesdiv='IV' then total=73876;
if year=2016 and icesdiv='IV' then denmark=28869;

*********************Skift år her*******************;
if year=2017 and icesdiv='IIIa' then totIIIa=37107.4;
if year=2017 and icesdiv='IIIa' then DKIIIa=37007.4;
if year=2017 and icesdiv='IV' then total=480391.2;
if year=2017 and icesdiv='IV' then denmark=316839;

if year=2018 and icesdiv='IIIa' then totIIIa=8337.000;
if year=2018 and icesdiv='IIIa' then DKIIIa=8337.000;
if year=2018 and icesdiv='IV' then total=263273.05;
if year=2018 and icesdiv='IV' then denmark=167282.90;

if year=2019 and icesdiv='IIIa' then totIIIa=552.000;
if year=2019 and icesdiv='IIIa' then DKIIIa=552.000;
if year=2019 and icesdiv='IV' then total=236536.77;
if year=2019 and icesdiv='IV' then denmark=93181.00;

if year=2020 and icesdiv='IIIa' then totIIIa=6489.923;
if year=2020 and icesdiv='IIIa' then DKIIIa=6489.923;
if year=2020 and icesdiv='IV' then total=440275.40;
if year=2020 and icesdiv='IV' then denmark=162666.21;

if year=2021 and icesdiv='IIIa' then totIIIa=2488.797;
if year=2021 and icesdiv='IIIa' then DKIIIa=2488.797;
if year=2021 and icesdiv='IV' then total=230120.762;
if year=2021 and icesdiv='IV' then denmark=67021.406;

if year=2022 and icesdiv='IIIa' then totIIIa=12013.207; *Updated 240112 from PreliminaryCatchesFor2022;
if year=2022 and icesdiv='IIIa' then DKIIIa=11637.3; *Updated 240112 from PreliminaryCatchesFor2022;
if year=2022 and icesdiv='IV' then total=154614.653; *Updated 240112 from PreliminaryCatchesFor2022;
if year=2022 and icesdiv='IV' then denmark=61013.5; *Updated 240112 from PreliminaryCatchesFor2022;

if year=2023 and icesdiv='IIIa' then totIIIa=2171.11; *Updated 250107 from PreliminaryCatchesFor2022;
if year=2023 and icesdiv='IIIa' then DKIIIa=2171.11; *Updated 250107 from PreliminaryCatchesFor2022;
if year=2023 and icesdiv='IV' then total=161515.2673; *Updated 250107 from PreliminaryCatchesFor2022;
if year=2023 and icesdiv='IV' then denmark=116017; *Updated 250107 from PreliminaryCatchesFor2022;

if year=2024 and icesdiv='IIIa' then totIIIa=47.54; *Updated 260112 from PreliminaryCatchesFor2024;
if year=2024 and icesdiv='IIIa' then DKIIIa=47.54; *Updated 260112 from PreliminaryCatchesFor2024;
if year=2024 and icesdiv='IV' then total=95816.5092; *Updated 260112 from PreliminaryCatchesFor2024;
if year=2024 and icesdiv='IV' then denmark=69419.99; *Updated 260112 from PreliminaryCatchesFor2024;

if year=2025 and icesdiv='IIIa' then totIIIa=1812.853602; *Added 260109 from square file;
if year=2025 and icesdiv='IIIa' then DKIIIa=1797.85360182652; *Added 260109 from square file;
if year=2025 and icesdiv='IV' then total=105038.9404; *Added 260109 from square file;
if year=2025 and icesdiv='IV' then denmark=77431.1614; *Added 260109 from square file;

if icesdiv='IV' then ton=ton*denmark/dktondiv;
if icesdiv='IIIa' then ton=ton*DKIIIa/dktondiv;
if icesdiv='IV' then iton=iton*(total-denmark)/itondiv;
if icesdiv='IIIa' then iton=iton*(totIIIa-DKIIIa)/itondiv;
if icesdiv='IV' then totton=totton*(total)/ttondiv;
if icesdiv='IIIa' then totton=totton*(totIIIa)/ttondiv;

if icesdiv='IV' and year le 1993 then iton=totton*(total-denmark)/total;
if icesdiv='IV' and year le 1993 then ton=totton*denmark/total;
if icesdiv='IV' and year le 1993 then totton=totton;
if icesdiv='IIIa' and year le 1996 then iton=totton*(totIIIa-DKIIIa)/totIIIa;  ***Ingen square i IIIa*;
if icesdiv='IIIa' and year le 1993 then ton=totton*DKIIIa/totIIIa;
if icesdiv='IIIa' and year le 1993 then totton=totton;
if icesdiv='IIIa' and year=2009 then iton=totton*(totIIIa-DKIIIa)/totIIIa;  ***Ingen square i IIIa*;
if icesdiv='IIIa' and year=2009 then totton=totton;

*if icesdiv='IV' then totton=totton*total/ttondiv;
*if icesdiv='IIIa' then totton=totton*totIIIa/ttondiv;
if iton=. then iton=0;
totton=ton+iton;
dkton=ton;
intton=iton;
aar=year;
if icesdiv='' then delete;
run;

proc sort data=t13;
by year icesdiv ;
run;

proc summary data=t13;
var intton dkton totton;
by year icesdiv ;
output out=x (drop=_type_ _freq_) sum()=;
run;

proc sort data=t13;
by square;
run;

data cb6;
merge t13 area;
by square;
run;

proc sort data=cb6;
by aar month square;
run;

data x1;

*********************Skift år her*******************;

set out.mean_weight_and_n_per_kg_83_&timeseries_end.;
hy=1;
if month ge 7 then hy=2;
year=aar;
PP_ar_tx=put(square,$PPareas.);
if PP_ar_tx in ('1B','1C','2B','2C','3','SH','3AS','3AN') then NNSN='NN';
if PP_ar_tx in ('1A','2A','4','5','6') then NNSN='SN';
*drop PP_ar_tx;
drop area;
run;

proc sort data=x1;
by year NNSN hy;
run;

data x2;
 merge x1 in.canumweca;
 by year NNSN hy;
 run;

data x3;
set x2;
if year lt 1993 then n0_per_kg=1000*n0/(sumnw);
if year lt 1993 then mw0=w0/1000; *Changed - open this line and similar lines below;
if year lt 1993 then n1_per_kg=1000*n1/(sumnw);
if year lt 1993 then mw1=w1/1000;
if year lt 1993 then n2_per_kg=1000*n2/(sumnw);
if year lt 1993 then mw2=w2/1000;
if year lt 1993 then n3_per_kg=1000*n3/(sumnw);
if year lt 1993 then mw3=w3/1000;
if year lt 1993 then n4_per_kg=1000*n4/(sumnw);
if year lt 1993 then mw4=w4/1000;

sop=n0_per_kg*mw0+n1_per_kg*mw1+n2_per_kg*mw2+n3_per_kg*mw3+n4_per_kg*mw4; *Changed;
drop year sumnw n0-n4 w0-w4 hy season NNSN pp_ar_tx year area sop; *Changed;
run;

proc sort data=x3;
by square;
run;

data x3b;
merge x3 area;
by square;
run;

proc sort data=x3b;
by aar month square;
run;

data cb9;
merge cb6 x3b;
by aar month square;
run;

proc summary data=cb9;
var intton dkton totton;
by aar ;
output out=x4 (drop=_type_ _freq_) sum()=;
run;

data cb10;
set cb9;

*if dkton=intton=. then delete;
*if dkton=0 and intton in (0,.) then delete;
if area in ('.', 'NA') then delete;
if aar=. then delete;

*****************Misreporting correction******************;
*****************NOT INCLUDED WHEN MAKING DATA FOR EFFORT**************;

if &scenario. in ('WKSAND16', 'WKSAND22a', 'WKSAND22b') then do;
if aar in (2014,2015) and square in ('41F1','41F2','41F3') then area= '1r'; *Changed - opened;
end;
if &scenario. in ('NS', 'NS_minus_3a') then do;
if aar in (2014,2015) and square in ('41F1','41F2','41F3') then area= 'S'; *Changed - opened;
end;

if 1*month=. then delete;
if 1*month lt 7 then hy=1;
if 1*month ge 7 then hy=2;

dkn0=dkton*n0_per_kg;
dkn1=dkton*n1_per_kg;
dkn2=dkton*n2_per_kg;
dkn3=dkton*n3_per_kg;
dkn4=dkton*n4_per_kg;
dkwmw0=dkn0*mw0;
dkwmw1=dkn1*mw1;
dkwmw2=dkn2*mw2;
dkwmw3=dkn3*mw3;
dkwmw4=dkn4*mw4;

inn0=intton*n0_per_kg;
inn1=intton*n1_per_kg;
inn2=intton*n2_per_kg;
inn3=intton*n3_per_kg;
inn4=intton*n4_per_kg;
inwmw0=inn0*mw0;
inwmw1=inn1*mw1;
inwmw2=inn2*mw2;
inwmw3=inn3*mw3;
inwmw4=inn4*mw4;

totn0=totton*n0_per_kg;
totn1=totton*n1_per_kg;
totn2=totton*n2_per_kg;
totn3=totton*n3_per_kg;
totn4=totton*n4_per_kg;
totwmw0=totn0*mw0;
totwmw1=totn1*mw1;
totwmw2=totn2*mw2;
totwmw3=totn3*mw3;
totwmw4=totn4*mw4;

run;

proc sort data=cb10 out=cb11;
by area aar hy;
run;

proc summary data=cb11;
var dkn0-dkn4 dkwmw0-dkwmw4 dkton
inn0-inn4 inwmw0-inwmw4 intton
totn0-totn4 totwmw0-totwmw4 totton n_samples 
;
by area aar hy;
output out=cb12 (drop=_type_ _freq_) sum()=;
run;

data cb13;
set cb12;
dkmw0=dkwmw0/dkn0;
dkmw1=dkwmw1/dkn1;
dkmw2=dkwmw2/dkn2;
dkmw3=dkwmw3/dkn3;
dkmw4=dkwmw4/dkn4;

inmw0=inwmw0/inn0;
inmw1=inwmw1/inn1;
inmw2=inwmw2/inn2;
inmw3=inwmw3/inn3;
inmw4=inwmw4/inn4;

totmw0=totwmw0/totn0;
totmw1=totwmw1/totn1;
totmw2=totwmw2/totn2;
totmw3=totwmw3/totn3;
totmw4=totwmw4/totn4;
year=aar;

label  n_samples='Number of length samples taken in the area that year'
 ;
drop dkwmw0-dkwmw4 inwmw0-inwmw4 totwmw0-totwmw4 _type_ _freq_;

run;

*****************Indsæt 0-år og middelvægt for hele perioden hvor W=.;

proc sort data=cb13 out=m14 (keep=area aar hy) nodupkey;
by area;
run;

data m15;
set m14;

*********************Skift år her*******************;

do aar=1983 to 2022 by 1;
output;
end;
run;

data m15a;
set m15;
do hy=1,2;
output;
end;
run;

data m16;
merge cb13 m15a;
by area aar hy;
run;

data m17;
set m16;
if dkn0=. then dkn0=0;
if dkn1=. then dkn1=0;
if dkn2=. then dkn2=0;
if dkn3=. then dkn3=0;
if dkn4=. then dkn4=0;

if inn0=. then inn0=0;
if inn1=. then inn1=0;
if inn2=. then inn2=0;
if inn3=. then inn3=0;
if inn4=. then inn4=0;

if totn0=. then totn0=0;
if totn1=. then totn1=0;
if totn2=. then totn2=0;
if totn3=. then totn3=0;
if totn4=. then totn4=0;

if dkton=. then dkton=0;
if intton=. then intton=0;
if totton=. then totton=0;

if aar=. then delete;
if area in ('.', 'NA') then delete;

run;

proc sort data=m17;
by area hy;
run;

proc summary data=m17;
var totmw0-totmw4;
by area hy;
output out=m18 (drop=_type_ _freq_) mean(totmw0)=mmw0 mean(totmw1)=mmw1 
mean(totmw2)=mmw2 mean(totmw3)=mmw3 mean(totmw4)=mmw4
;
run;

data m19;
merge m17 m18;
by area hy;
run;

data m20;
set m19;
if dkmw0=. then dkmw0=mmw0;
if dkmw1=. then dkmw1=mmw1;
if dkmw2=. then dkmw2=mmw2;
if dkmw3=. then dkmw3=mmw3;
if dkmw4=. then dkmw4=mmw4;

if inmw0=. then inmw0=mmw0;
if inmw1=. then inmw1=mmw1;
if inmw2=. then inmw2=mmw2;
if inmw3=. then inmw3=mmw3;
if inmw4=. then inmw4=mmw4;

if totmw0=. then totmw0=mmw0;
if totmw1=. then totmw1=mmw1;
if totmw2=. then totmw2=mmw2;
if totmw3=. then totmw3=mmw3;
if totmw4=. then totmw4=mmw4;

if year ge 1993 and n_samples lt 5  then totmw0=mmw0;
if year ge 1993 and n_samples lt 5  then totmw1=mmw1;
if year ge 1993 and n_samples lt 5  then totmw2=mmw2;
if year ge 1993 and n_samples lt 5  then totmw3=mmw3;
if year ge 1993 and n_samples lt 5  then totmw4=mmw4;

drop mmw0-mmw4;
run;

********SOP korrektion af mw***************************************************;


data m23;
set m20;

if n_samples=. then n_samnples=0;

sopcorr=totton/(totn0*totmw0+totn1*totmw1+totn2*totmw2+totn3*totmw3+totn4*totmw4);
if totton=0 then sopcorr=1;
if sopcorr=. then sopcorr=1;
n0=totn0;
n1=totn1;
n2=totn2;
n3=totn3;
n4=totn4;
mw0=sopcorr*totmw0;
mw1=sopcorr*totmw1;
mw2=sopcorr*totmw2;
mw3=sopcorr*totmw3;
mw4=sopcorr*totmw4;
ton=totton;
sop=n0*mw0+n1*mw1+n2*mw2+n3*mw3+n4*mw4;
keep sopcorr area aar hy n0-n4 mw0-mw4 ton n_samples; *Changed - included sopcorr in output;
run;

proc gplot data=m23;
plot (n0-n4)*aar/overlay;
by area;
symbol1 v=0 i=join;
symbol2 v=1 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;

run;



proc gplot data=m23;
plot (mw0-mw4)*aar/overlay;
by area hy;
symbol1 v=0 i=join;
symbol2 v=1 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;

run;


proc gplot data=m23;
plot (ton n_samples)*aar=area;
symbol1 v=0 i=join;
symbol2 v=1 i=join;
symbol3 v=2 i=join;
symbol4 v=3 i=join;
symbol5 v=4 i=join;

run;

******Eksporter til Total_catch_in_numbers_and_mean_weight_new_areas_2009.csv**;


*********************Skift år her*******************;

data out.catch_in_numbers_and_mw_&timeseries_start._&timeseries_end.;
set m23;

run;
proc export data=m23
   outfile="&path_output.\catch_in_numbers_and_mw_&timeseries_start._&timeseries_end..csv"
   dbms=csv 
   replace;
run;
quit;

/*

***fraction by area****;
proc sort data=m23 out=m24;
by aar area;
run;

proc summary data=m24;
var ton;
by aar area;
output out=m25 (drop=_type_ _freq_) sum()=;
run;


proc summary data=m25;
var ton;
by aar;
output out=m26 (drop=_type_ _freq_) sum()=totton;
run;

data m27;
merge m25 m26;
by aar;
run;

data m28;
set m27;
prop=ton/totton;

run;

proc gplot data=m28;
plot prop*aar=area;
symbol v=plus i=join;
run;

proc sort data=m28;
by area;
run;

proc summary data=m28;
var prop;
by area;
output out=m29 (drop=_type_ _freq_) mean()=;
run;
