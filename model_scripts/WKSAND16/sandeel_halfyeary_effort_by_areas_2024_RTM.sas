**********************************************************
 Standardisering af effort til assessment**;
**********************************************************;

*libname san 'c:\ar\sas\sandeel';
*libname age_ssd 'c:\ar\sas\sandeel\ALK.';
%let scenario = WKSAND16;

%let path_input = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\data;
%let output_folder = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\model;
%let path_output = &output_folder.\&scenario.;

%let path_ref = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\boot\data\references;

libname in "&path_input.";
libname out "&path_output.";


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

data s1;
set in.cpue_2025;
julday=fishjulday-days/2;
if end_date=. then julday=fishjulday+days/2;
julw=round(julday,7);
square=ices_txt;
if month not in (4,5) then delete;
if month=4 and stday lt 15 then delete;
if endmon in ('JUN') then delete;
if endmon in ('MAY') and endday gt 6 then delete;
if endmon in ('MAY') and endday=. and stday gt 15 then delete;
grtmin=substr(grt_int,1,4);
grtmax=substr(grt_int,6,4);
id=substr(grt_int,4,1);
if id='-' then grtmin=substr(grt_int,1,3);
if id='-' then grtmax=substr(grt_int,5,4);
grtmean=(grtmin+grtmax)/2;
if grtmean=9999 then grtmean=.;
if grt_num=. then grt_num=grtmean;
if 1*month=. then delete;
if 1*month lt 7 then hy=1;
if 1*month ge 7 then hy=2;
if year lt 1999 then delete;
country='DEN';
run;

proc sort data=s1;
by  year;
run;

proc summary data=s1;
var grtmean;
by  year ;
output out=g1 mean()= p50()=median p5()=min5 p95()=max5 min()=min max()=max;
run;

*proc gplot data=s1;
*plot grt_num*grtmean;
*symbol v=plus i=r;
*run;

proc sort data=s1;
by square;
run;

proc sort data=area out=s1b;
by square;
run;

data s1c;
merge s1 s1b;
by square;
run;


**********************Korrigeret effort ***********************************;
****standardiseret med effekt af bådsstørrelse/KW på catchability)*********;

data s1d;
set s1c;
if cpue=. then delete;
lngrt=log(1*grt_num/200);
lnkw=log(1*kwmax/500);
lncpue=log(cpue);
*if lncpue lt -4 then delete;
*if year in (2012) then country='DEN';*No significant difference between the two***********;
run;

data p5;
set s1d ;
if square='99A9' or square='.A9' then delete;
*if year ne 2009 then delete;
*if area ne 1 then delete;
*if country='NOR' then delete;
*if year lt 1989 then delete;
*if year gt 1998 then delete;
y=1*year;
*if y lt 1984 then dec=1;
if dec ne 1 and y lt 1989 then dec=2;
*if dec not in (1,2) and y lt 1994 then dec=3;
if dec not in (1,2,3) and y lt 1999 then dec=4;
if dec not in (1,2,3,4) and y lt 2006 then dec=5;
if dec not in (1,2,3,4,5) and y lt 2017 then dec=6;
if dec not in (1,2,3,4,5,6) and y ge 2017 then dec=7;
*dec=1*year;
run;

proc sort data=p5;
by dec year  square julw;
run;

ods graphics on;

proc glimmix data=p5 plots=RESIDUALPANEL;
class square year month  fid;
model lncpue= lngrt*year /solution;
*output out=s2 p=pred r=r;
random year*square fid;
*by dec ;
ods output ParameterEstimates=p6 estimate=pp6;
run;

ods graphics off;

*proc gplot data=s2;
*plot pred*lngrt=country;
*by year ;
*symbol1 v=plus c=black i=r;
*symbol2 v=plus c=red i=r;
*symbo/l3 v=plus c=blue i=r;
*symbol4 v=plus c=green i=r;
*run;

data s3a;
set p6;
if effect ne 'lngrt*year' then delete;
bcorr1=estimate;
keep year bcorr1;
run;


proc print data=s3a;
var year bcorr1;
run;

proc sort data=p5 out=s4 ;
by year;
run;

data s5;
merge s4 s3a;
by year;
run;
/**/

**************Straight sum of number of days per week area16****************;

data mixed_s6;
set s5;
*if year=2014 then bcorr1=0.453;
*if year=2014 then acorr1=log(0.43);
corr1=(1*grt_num/200)**bcorr1;
dayscor1=days*corr1;
*area='  ';
*area= area16;
*if area16='1r' then area='1';
*if area16='2r' then area='2';
*if area16='3r' then area='3';
if dayscor1=. then delete;
if hy=. then delete;
*if area=. then delete;
run;

*proc gplot data=mixed_s6;
*plot dayscor1*days=country;
*by year;
*run;


*************Data fra catch_by_age***;
proc sort data=out.mean_weight_and_n_per_kg_83_25 out=t10;
by area aar square;
run;

data xxx;
set t10;
year=aar;
*if area='1r' then area='1';
*if area='2r' then area='2';
*if area='3r' then area='3';
if month ne 4 then delete;
*if aar lt 1999 then delete;
run;

proc sort data=mixed_s6;
by area year square;
run;

data t11;
merge mixed_s6 xxx;
by area year square;
run;

data t12;
set t11;
if hy=. then delete;
c0=yield*n0_per_kg;
c1=yield*n1_per_kg;
c2=yield*n2_per_kg;
c3=yield*n3_per_kg;
c4=yield*n4_per_kg;
if hy=2 then delete;
*if area ne 1 then delete;
*april1=cpue1;
*april2=cpue2;
*april3=cpue3;
*april4=cpue4;
*keep year area n_samples cpue0-cpue4 eff_catch;
*keep year area april1 april2 april3 april4;
run;

proc sort data=t12;
by area year;
run;

proc summary data=t12;
var days dayscor1 yield c0-c4;
by area year;
output out=o3a (drop=_type_ _freq_) sum()=;
run;

proc summary data=xxx;
var n_samples;
by area year;
output out=o3b (drop=_type_ _freq_) sum()=;
run;

data o3c;
merge o3a o3b;
by area year;
run;

data o4;
set o3c;
effort1=days;
effort2=dayscor1;
eff_catch=yield;
keep area year effort1 effort2 eff_catch c0-c4 n_samples; 
run;

*proc gplot data=o4;
*plot effort2*dectime=year;
*by area;
*run;

proc sort data=o4 (drop=year) out=t3 nodupkey;
by area;
run;

data t4;
set t3;

*********************Skift år her*******************;

do year=1983 to 2025 by 1;
output;
end;
run;

data t6;
set t4;
effort1=0;
effort2=0;
eff_catch=0;
c0=0;
c1=0;
c2=0;
c3=0;
c4=0;
n_samples=0;
run;

data t7;
set o4 t6;
keep area year effort1 effort2  eff_catch c0-c4 n_samples;
run;

proc sort data=t7;
by area year;
run;

proc summary data=t7;
var effort1 effort2  eff_catch c0-c4 n_samples;
by area year;
output out=t8 sum()=;
run;

data RTM_2023_area16;
set t8;
*if area=. then delete;
if eff_catch=. then eff_catch=0;
cpue1=0.001*c1/effort2;
cpue2=0.001*c2/effort2;
cpue3=0.001*c3/effort2;
cpue4=0.001*c4/effort2;
if n_samples lt 30 then cpue1=.;
if n_samples lt 30 then cpue2=.;
if n_samples lt 30 then cpue3=.;
if n_samples lt 30 then cpue4=.;
cpue=eff_catch/effort2;
keep area year effort1 effort2 eff_catch cpue1-cpue4 n_samples;
run;

*proc export data=RTM_2022_area16
   outfile='c:\ar\tobis\logbooks\RTM_2022.csv'
   dbms=csv 
   replace;
*run;
*quit;


proc export data=RTM_2023_area16
   outfile="&path_output.\RTM_2025_area16.csv"
   dbms=csv 
   replace;
run;
quit;


*proc gplot data=mixed_t9_rtm;
*plot (cpue1 cpue2 )*year/overlay;
*by area hy;
*symbol v=plus i=join;
*run;


proc sort data=RTM_2023_area16;
by area;
run;

proc gplot data=RTM_2023_area16;
plot (cpue1 cpue2 cpue3 cpue4)*year/overlay;
by area;
symbol1 v=plus i=join;
run;
/*
******Eksporter til csv**;

proc export data=t12
   outfile='c:\ar\tobis\logbooks\cpue_to_sandeel_assessment_RTM_2022_WKSAN16.csv'
   dbms=csv 
   replace;
run;
quit;
/*
******Eksporter til csv**;

*proc export data=t12
   outfile='C:\ar\tobis\logbooks\cpue_to_sandeel_assessment_RTM_fishing_days_3_squares.csv'
   dbms=csv 
   replace;
*run;
*quit;


proc gplot data=t12;
plot (cpue1-cpue4)*year/overlay;
by area;
symbol1 v=plus i=join;
symbol2 v=plus i=join;
symbol3 v=plus i=join;
symbol4 v=plus i=join;
run;
/*
proc gplot data=t12;
plot cpue1*n1perton/overlay;
by area;
run;

proc gplot data=t12;
plot cpue2*n2perton/overlay;
by area;
run;

proc gplot data=t12;
plot cpue3*n3perton/overlay;
by area;
run;
/*
*****Catch variability by square**;


proc sort data=s1c;
by area year hy month square;
run;

proc summary data=s1c;
var  yield;
by area year hy month square;
output out=cv1 sum(yield)=sq_catch;
run;

proc sort data=s6;
by area year hy month square;
run;

proc summary data=s6;
var dayscor1 yield;
by area year hy month square;
output out=cv4 sum()=;
run;

data cv2;
set cv4;
lncatch=log(yield/dayscor1);
if month ne 4 then delete;
if lncatch=. then delete;
run;

proc summary data=cv2;
var lncatch yield dayscor1;
by area year;
output out=cv3a mean(lncatch)=m_catch std(lncatch)=stdcatch n(lncatch)=nsq sum(yield)=yield sum(dayscor1)=days;
run;

proc sort data=cv7;
by year;
run;

data cv8;
set cv7;
if _type_ ne 'ERROR' then delete;
stde=(ss/df)**0.5;
keep year stde;
run;

proc sort data=cv3a;
by year;
run;

data cv9;
merge cv3a cv8;
by year;
run;

proc sort data=cv9;
by area;
run;

proc gplot data=cv9;
plot (m_catch stdcatch nsq stde yield days)*year=area;
symbol1 v=0 i=j;
symbol2 v=1 i=j;
symbol3 v=2 i=j;
symbol4 v=3 i=j;
symbol5 v=4 i=j;
symbol6 v=5 i=j;
symbol7 v=6 i=j;
symbol7 v=7 i=j;
run;

data cv10;
set cv9;
if area=. then delete;
if area ge 4 then delete;
*if year=2013 then delete;
*if year=2014 then delete;
lny=log(yield);
lnd=log(days);

run;

proc gplot data=cv10;
plot ( stdcatch nsq stde m_catch)*(lnd)=area;
*by area;
symbol1 v=1 i=r;
symbol2 v=2 i=r;
symbol3 v=3 i=r;
symbol4 v=4 i=r;
symbol5 v=5 i=r;
symbol6 v=6 i=r;
symbol7 v=7 i=r;

run;

proc corr data=cv10;
var year m_catch stdcatch stde nsq yield days lny lnd; 
by area;
run;

******Eksporter til csv**;
*proc export data=cv9
   outfile='C:\ar\tobis\rtm\data_for_figures_2016_3_squares.csv'
   dbms=csv 
   replace;
*run;
*quit;


/*
**Sammenligning med alle squares resultat**************;

data sa1;
set cv3;
m_all=m_catch;
days_all=days;
if m_all lt 1.5 then delete;
keep year m_all days_all area;
run;

proc sort data=sa1;
by area year;
run;

proc sort data=cv10;
by area year;
run;


data sa2;
merge sa1 cv10;
by area year;
run;

proc gplot data=sa2;
plot m_all*m_catch=area;
run;

proc gplot data=sa2;
plot days_all*days=area;
run;

proc corr data=sa2;
var year m_all m_catch days_all days;
by area;
run;
