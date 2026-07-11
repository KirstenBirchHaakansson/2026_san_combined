/* Jenner bundle: the $PPareas format below is copied unchanged from
   model_scripts/WKSAND16/hj_formats.sas (%include'd by the upstream
   script) so this excerpt is self-contained. */
proc format;
   value  $PPareas

  "37E6" -"37E9"="1A"
  "37F0" -"37F2"="1A"
  "38E6" -"38E9"="1A"
  "38F0" -"38F2"="1A"
  "39E8" -"39E9"="1A"
  "39F0" -"39F2"="1A"
  "40E6" -"40E9"="1A"
  "40F0" -"40F2"="1A"
  "41E6" -"41E9"="1A"
  "41F0" -"41F2"="1A"

  "42E6" -"42E9"="1B"
  "42F0" -"42F2"="1B"
  "43E6" -"43E9"="1B"
  "43F0" -"43F2"="1B"
  "44E6" -"44E9"="1B"
  "44F0" -"44F2"="1B"
  "45E6" -"45E9"="1B"
  "45F0" -"45F2"="1B"
  "46E6" -"46E9"="1B"
  "46F0" -"46F2"="1B"

  "47E6"="1C"
  "47F0" -"47F2"="1C"
  "48E6"="1C"
  "48F0" -"48F2"="1C"
  "49E6"="1C"
  "49F0" -"49F2"="1C"
  "50E6"="1C"
  "50F0" -"50F2"="1C"
  "51E6"="1C"
  "51F0" -"51F2"="1C"
  "52E6" -"52E9"="1C"
  "52F0" -"52F2"="1C"

  "47E7" -"47E9"="SH"
  "48E7" -"48E9"="SH"
  "49E7" -"49E9"="SH"
  "50E7" -"50E9"="SH"
  "51E7" -"51E9"="SH"

  "37F3" -"37F5"="2A"
  "38F3" -"38F5"="2A"
  "39F3" -"39F5"="2A"
  "40F3" -"40F5"="2A"
  "41F3" -"41F5"="2A"

  "42F3" -"42F5"="2B"
  "43F3" -"43F5"="2B"
  "44F3" -"44F5"="2B"
  "45F3" -"45F5"="2B"
  "46F3" -"46F6"="2B"

  "47F3" -"47F5"="2C"
  "48F3" -"48F5"="2C"
  "49F3" -"49F5"="2C"
  "50F3" -"50F5"="2C"
  "51F3" -"51F5"="2C"
  "52F3" -"52F5"="2C"

  "41F6" -"41F8"="3"
  "42F6" -"42F8"="3"
  "43F6" -"43F7"="3"
  "44F6" ="3"
  "45F6" ="3"

  "43F8" -"43F9"="3AN"
  "44F7" -"44F9"="3AN"
  "44G0" ="3AN"
  "45F7" -"45F9"="3AN"
  "45G0" -"45G1"="3AN"
  "46F8" -"46F9"="3AN"
  "46G0" -"46G1"="3AN"
  "47F8" -"47F9"="3AN"
  "47G0" -"47G1"="3AN"
  "48G0" ="3AN"

  "41F9" ="3AS"
  "41G0" -"41G2"="3AS"
  "42G0" -"42G2"="3AS"
  "43G0" -"43G2"="3AS"
  "44G1" ="3AS"

  "31E6" -"31E9"="4"
  "31F0" -"31F2"="4"
  "32E6" -"32E9"="4"
  "32F0" -"32F2"="4"
  "33E6" -"33E9"="4"
  "33F0" -"33F2"="4"
  "34E6" -"34E9"="4"
  "34F0" -"34F2"="4"
  "35E6" -"35E9"="4"
  "35F0" -"35F2"="4"
  "36E6" -"36E9"="4"
  "36F0" -"36F2"="4"

  "31F3" -"31F5"="5"
  "32F3" -"32F5"="5"
  "33F3" -"33F5"="5"
  "34F3" -"34F5"="5"
  "35F3" -"35F5"="5"
  "36F3" -"36F5"="5"

  "35F6" -"35F8"="6"
  "36F6" -"36F8"="6"
  "37F6" -"37F8"="6"
  "38F6" -"38F8"="6"
  "39F6" -"39F8"="6"
  "40F6" -"40F9"="6"

   other       = "999";
   run;

/* Jenner bundle: from model_scripts/WKSAND16/34_catch_by_age_and_mean_weight.sas
   (the "1989-1993" DK catch-by-square aggregation block). Upstream reads
   in.cpue_2017 (built by data_scripts/CPUEin_*.sas, see t002_cpue_indl);
   this bundle substitutes a small DATALINES block with the same columns
   for the years 1985-1988. Every transformation line is unchanged. */
data c1;
input year yield endday stday st_date end_date days month ices_txt $;
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
datalines;
1985 4.2 12 5 . . 1 3 41F3
1985 3.9 13 6 . . 1 3 41F3
1986 5.6 11 12 . . 1 4 42F4
1986 5.1 12 19 . . 1 4 42F4
1987 7.2 2 3 . . 2 5 43F5
1987 4.3 15 15 . . 1 5 43F5
1988 8.9 10 2 . . 1 6 44F6
1988 8.1 11 18 . . 1 6 44F6
;
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

proc print data=c2ab;
   var year month square PP_ar_tx ICESdiv ton PP_ton;
run;
