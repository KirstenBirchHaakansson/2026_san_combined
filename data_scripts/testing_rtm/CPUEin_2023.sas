**********************************************************
              Read cpue data
**********************************************************;

/**/
%let path_dnk_effort = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\boot\data\data_for_testing_rtm;
%let path_nor_effort = C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\boot\data\data_for_testing_rtm;
libname out 'C:\Users\kibi\OneDrive - Danmarks Tekniske Universitet\stock_coord_work\san\2026_san_combined\data\testing_rtm';

%macro indl(yy);

data c&yy.;
   LENGTH fid $ 8 lognr $ 10 gear $ 3 grt_int $ 9 fvd $ 4 ICES_txt $ 4
          sttime $ 14 endtime $ 14  spec $ 3;

 	  infile "&path_dnk_effort.\tbs_&yy._logdata.csv" 	  delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;


      INPUT fid lognr year  month  GRT_int  gear spec fvd ICES_txt sttime endtime hours_absent  
            kwmax  yield days_trip days cpue;

      days_absent=ceil(hours_absent/24);

	  
   yield=yield/1000;

   CPUE=cpue/1000;

  
   stday=1*substr(sttime,1,2);
   stmon=substr(sttime,3,3);
   endday=1*substr(endtime,1,2);
   endmon=substr(endtime,3,3);
   
   stmonn=stmon;
   endmonn=endmon;

 st_date=input (put(stday,$2.) || put(stmonn,$3.) || substr(put(year,$4.),3,2),date7.);   
   if endday=. then end_date=.; *first years of data;
      else end_date=input (put(endday,$2.) || put(endmonn,$3.) || substr(put(year,$4.),3,2),date7.);    
   sec=0;   

sthour=1*substr(sttime,9,2);
endhour=1*substr(endtime,9,2);
stmin=1*substr(sttime,12,2);
endmin= 1*substr(endtime,12,2);

 
   st_timesas=DHMS(st_date,sthour,stmin,sec);
   if stmin=. then st_timesas=DHMS(st_date,sthour,0,0);
   if sthour=. then st_timesas=DHMS(st_date,6,0,0);
   if end_date=. then end_timesas=.; *first years of data;
      else end_timesas=DHMS(end_date,endhour,endmin,sec);
   if end_date ne . and endmin=.
      then end_timesas=DHMS(end_date,endhour,0,0);

   st_timetxt=put(st_timesas,datetime18.);

   end_timetxt=put(end_timesas,datetime18.);
 
   if not(end_timesas=.) then fish_timesas=(st_timesas+end_timesas)/2;
      else fish_timesas=st_timesas;

   if fish_timesas=. then fish_timetxt=' '; *first years of data;
      else fish_timetxt=put(fish_timesas,datetime18.);


   fishjulday=(datepart(st_timesas)- mdy(01,01,year))+1;

   if floor(fishjulday/7)=fishjulday/7 then fishweek=fishjulday/7;
   else fishweek=floor(fishjulday/7)+1;

   if end_timesas>0 then tripdur=(end_timesas-st_timesas)/(60*60*24);
   else tripdur=.;
run;

%mend indl;

       
%indl(82);
%indl(83);
%indl(84);
%indl(85);
%indl(86);
%indl(87);
%indl(88);
%indl(89);
%indl(90);
%indl(91);
%indl(92);
%indl(93);
%indl(94);
%indl(95);
%indl(96);
%indl(97);
%indl(98);
%indl(99);
%indl(00);
%indl(01);
%indl(02);
%indl(03);
%indl(04);
%indl(05);
%indl(06);
%indl(07);
%indl(08);
%indl(09);
%indl(10);
%indl(11);
%indl(12);
%indl(13);
%indl(14);
%indl(15);
%indl(16);
%indl(17);
%indl(18);
%indl(19);
%indl(20);
%indl(21);
%indl(22);
%indl(23);
*%indl(24);
*%indl(25);


data out.cpue_2023;
set c82 c83 c84 c85 c86 c87 c88 c89 c90 c91 c92 c93 
c94 c95 c96 c97 c98 c99 c00 c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 
c12 c13 c14 c15 c16 c17 c18 c19 c20 c21 c22 c23; * c24 c25;
country='   ';
country='DEN';
 
run;


****************Norwegian CPUE input***********;

data ny11;
infile "&path_nor_effort.\catch_byVessel_byDay_2011.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;
data ny12;
infile "&path_nor_effort.\catch_byVessel_byDay_2012.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;
data ny13;
infile "&path_nor_effort.\catch_byVessel_byDay_2013.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;
data ny14;
infile "&path_nor_effort.\catch_byVessel_byDay_2014.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;
data ny15;
infile "&path_nor_effort.\catch_byVessel_byDay_2015.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;

data ny16;
infile "&path_nor_effort.\catch_byVessel_byDay_2016.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;

data ny17;
infile "&path_nor_effort.\catch_byVessel_byDay_2017.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;

data ny18;
infile "&path_nor_effort.\catch_byVessel_byDay_2018.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;


data ny19;
infile "&path_nor_effort.\catch_byVessel_byDay_2019.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;


data ny20;
infile "&path_nor_effort.\catch_byVessel_byDay_2020.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;


data ny21;
infile "&path_nor_effort.\catch_byVessel_byDay_2021.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;

data ny22;
infile "&path_nor_effort.\catch_byVessel_byDay_2022.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;


data ny23;
infile "&path_nor_effort.\catch_byVessel_byDay_2023.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;

/*
data ny24;
infile "&path_nor_effort.\catch_byVessel_byDay_2024.csv" delimiter=',' 
MISSOVER DSD lrecl=32767 firstobs=2 ;
informat date $10. ices_txt $4. grt_int $ 9.  ;      
input    date $ ices_txt $ cpue grt_int $ ;

run;
*/

data out.norway_cpue_ny;
set ny11 ny12 ny13 ny14 ny15 ny16 ny17 ny18 ny19 ny20 ny21 ny22 ny23; *ny24;
country='   ';
country='NOR';
year=1*substr(date,1,4);
if year lt 2000 then year=1*substr(date,7,4);
month=1*substr(date,6,2);
day=1*substr(date,9,2);
fishjulday=((month-1)/12)*365+day;
yield=cpue;
days=1;
run;
