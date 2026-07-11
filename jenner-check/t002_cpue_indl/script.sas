**********************************************************
              Read cpue data
**********************************************************;

/**/
libname out (work);

%macro indl(yy);

data c&yy.;
   LENGTH fid $ 8 lognr $ 10 gear $ 3 grt_int $ 9 fvd $ 4 ICES_txt $ 4
          sttime $ 14 endtime $ 14  spec $ 3;

      /* Jenner bundle: upstream reads this via
         INFILE "&path_dnk_effort.\tbs_&yy._logdata.csv" DELIMITER=','
         MISSOVER DSD LRECL=32767 FIRSTOBS=2; the column layout, the
         macro body below, and every transformation are unchanged --
         only the input mechanism (DATALINES vs INFILE) differs, so
         the runner needs no uploaded file. */
      INPUT fid $ lognr $ year  month  GRT_int  gear $ spec $ fvd $ ICES_txt $ sttime $ endtime $ hours_absent
            kwmax  yield days_trip days cpue;
      datalines;
DK0012 100234 2025 3 150 OTB TBS 4001 41F3 01MAR25:06:00 01MAR25:12:00 18 285 4200 1 1 2333
DK0013 100235 2025 3 150 OTB TBS 4001 41F3 02MAR25:07:00 02MAR25:13:00 18 285 3900 1 1 2167
DK0014 100236 2025 4 220 OTB TBS 4002 42F4 05APR25:05:00 05APR25:11:00 18 340 5600 1 1 3111
DK0015 100237 2025 4 220 OTB TBS 4002 42F4 12APR25:06:00 12APR25:12:00 18 340 5100 1 1 2833
DK0016 100238 2025 5 180 OTB TBS 4003 43F5 03MAY25:08:00 03MAY25:20:00 18 310 7200 1 1 2571
DK0017 100239 2025 5 180 OTB TBS 4003 43F5 15MAY25:09:00 15MAY25:15:00 18 310 4300 1 1 2389
DK0018 100240 2025 6 275 OTB TBS 4004 44F6 02JUN25:04:00 02JUN25:10:00 18 410 8900 1 1 3448
DK0019 100241 2025 6 275 OTB TBS 4004 44F6 18JUN25:05:00 18JUN25:11:00 18 410 8100 1 1 3138
DK0020 100242 2025 11 150 OTB TBS 4001 41F3 05NOV25:11:00 05NOV25:17:00 18 285 3200 1 1 1780
;

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


%indl(25);

data out.cpue_2025;
set c25;
country='   ';
country='DEN';
run;

proc print data=out.cpue_2025 (obs=20);
   var fid year month ICES_txt gear yield cpue fishjulday fishweek tripdur;
run;
