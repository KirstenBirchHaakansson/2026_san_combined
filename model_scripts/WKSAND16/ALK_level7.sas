/**/

*****  Det følgende program kører på niveau 1 som %include statement i lgd age keys....sas****;
* Changed for WKSANDEEL 2022 - added all (drop=_type_ _freq_) to all proc summary;

data aglg5;
set out.aglg5a; *Libname changed for WKSANDEEL 2022;
if PP_ar_tx='' then delete;
if PP_ar_tx in ('1B','12C','2B','3','3AS','3AN','SH') then NS='N';
if PP_ar_tx in ('1A','2A','4','5','6') then NS='S';
if month*1 in (1.5,3) then month2='1-3';
if month*1 in (4,4.5,5,5.5) then month2='4-5';
if month*1 in (6.5,6,7,8) then month2='6-8';
if month*1 in (9.5,11.5) then month2='9-12';
run;

proc sort data=aglg5;
by geartype aar month2 NS scm;
run;

proc summary data=aglg5;
var n0-n4 s0-s4;             *stationer sammenlægges indenfor intsq;
by geartype aar month2 NS  scm;
output out=aglg5a (drop=_type_ _freq_) sum()=;
run;

*******  The dataset aglg4 contains the number of fish at age 0 1 2 3 4+     ***********
*******  as well as the number of fish of age 0 or greater,                ***********
*******  age 1 or greater, age 2 or greater and age-3 or greater           ***********;

data aglg6;
set aglg5a;
do age=0,1,2,3,4;
output;
 end;
  run;

data aglg7;
set aglg6;
if age=0 then n=n0;
if age=1 then n=n1;
if age=2 then n=n2;
if age=3 then n=n3;
if age=4 then n=n4;
if age=0 then s=s0;
if age=1 then s=s1;
if age=2 then s=s2;
if age=3 then s=s3;
if age=4 then s=s4;
if s=0 then n=.;       *;
if s=. then s=1;       *;
if s=0 then s=1;       *;
p=n/s0;
pi=n/s;                *pi er sandsynligheden for at være alder A eller ældre givet at man er alder A pr. lgd;
if pi=1 or pi/(1-pi)=0 then logit=.;
else logit=log(pi/(1-pi));  *logitten af pi;
run;
/*
proc gplot data=aglg7;
plot (n)*scm=age;
by geartype aar month;
title;
symbol1 v=plus i=join c=blue;
symbol2 v=plus i=join c=red;
symbol3 v=plus i=join c=green;
symbol4 v=plus i=join c=orange;
symbol5 v=plus i=join c=brown;
symbol6 v=plus i=join c=red;
run;
*/
proc sort data=aglg7;
by geartype aar month2 NS  age;
run;

*Antal fisk i aldersgruppen i alt i hver kombination af område, år, måned og geartype beregnes
*Hvis færre end 5 er aldersbestemt pr. længdegruppe eller færre end 5 er fundet i 
aldersgruppen tages den ikke med i den områdeopdelte-måneds opdelte analyse*; 

data aglg71;
set aglg7;
if n=. then delete;
run;

***Middelantal aldersbestemt pr længdegrupper, antal v. alder og 
***antal længdegupper samplet beregnes*;

proc summary data=aglg71;
var n s;
by geartype aar month2 NS  age;
output out=aglg7aa (drop=_type_ _freq_) sum(n)=nage sum(s)=means n(n)=nlengths;
run;

*Den maksimale og minimale længde observeret for en alder bestemmes. 
Sandsynligheden pi antages at være 0 ved max+2 og 1 ved min-2;

data aglg7a2;   
set aglg7;
if n=0 then delete; *delete hvor der ikke er aldersbestemt fisk;
if n=. then delete;
run;

proc summary data=aglg7a2;
var scm;
by geartype aar month2 NS   age;
output out=aglg7b (drop=_type_ _freq_) max()=maxscm min()=minscm;
run;

data aglg8;
merge aglg7 aglg7aa aglg7b;
by geartype aar month2 NS  age;
run;

data aglg8b;
set aglg8;
if means lt 10 and maxscm ne . then delete; **Bibeholder tilfælde hvor flere end 10 fisk  
er aldersbestemt men ingen var den pågældende alder**;
if nlengths le 1 then delete;
**********Alle fisk mere end to størrelseskategorier udenfor det observerede max og min 
(alle 0 eller 1-p-er) slettes da modellen ikke kan lide for mange 0-p'er og 1-p'er *********;
if maxscm ne . and maxscm lt 18 and scm gt maxscm+2 then n=.;
if maxscm ne . and maxscm=19 and scm gt maxscm+3 then n=.;
if maxscm ne . and maxscm gt 19 and scm gt maxscm+4 then n=.;
if minscm ne . and minscm lt 20 and scm lt minscm-2 then n=.;
if minscm ne . and minscm=22 and scm lt minscm-3 then n=.;
if minscm ne . and minscm ge 24 and scm lt minscm-4 then n=.;
run;
/*
proc gplot data=aglg8b;
plot (n)*scm=age;
by geartype aar month;
title;
symbol1 v=plus i=join c=blue;
symbol2 v=plus i=join c=red;
symbol3 v=plus i=join c=green;
symbol4 v=plus i=join c=orange;
symbol5 v=plus i=join c=brown;
symbol6 v=plus i=join c=red;
run;
/*

*******  Binomial model of the conditional probability of being age 1, 2, 3 and 4 respectively   ***********
*******  Factors length (linear), aar, position and gear tested                                 ***********
*******  Dispersion parameter is estimated, allowing for                                         ***********
*******  overdispersion (greater variance than in the binomial                                   ***********
*******  distribution). The Type 3 F-test should therefore be                                    ***********
*******  used when reducing the model                                                            ***********;
*/
data aglg9;
set aglg8b;
l2=scm*scm;                             *Da der typisk er lille overlap mellem aldrene antages det at spredningen i længde ved alder ca. er ens for alle aldre.
											med denne antagelse skal man ikke bruge et 2. grads led;
if age=4 then delete;   ****Den betingede sandsynlighed for at være 4+ er altid 1;
drop _type_ _freq_;
run;

proc sort data=aglg9;
by age  geartype aar month2 NS  maxscm minscm;
run;

*NB! ved at anvende n/s i stedet for pi indgår antallet af fisk som vægtning, hvis pi anvendes skal der tilføjes et weight statement;
ods;
           
proc genmod data=aglg9;          *model til generering af datasæt;
model n/s=scm
/dist=bin link=logit type1 type3 pscale obstats;
*make 'obstats' out=aglg12;

ods output obstats=aglg12;
by age geartype aar month2 NS  maxscm minscm;
run;

*******Deleting samples were the probability at maxsize exceeds that at minsize***;
proc sort data=aglg12;
by age geartype aar month2 NS;
run;

data aglg13;
set aglg12;
if scm=maxscm then maxp=pred;
if scm=minscm then minp=pred;
prange=upper-lower;
if n=. then prange=.;
sum=s;
if n=. then sum=.;
run;

proc summary data=aglg13;
var minp maxp prange sum;
by age geartype aar month2 NS;
output out=aglg13b (drop=_type_ _freq_) max()= sum(s)=sums;
run;


data aglg13c;
 merge aglg12 aglg13b;
 by age geartype aar month2 NS ;
 run;

*data aglg13d;
*set out.alk_level7;
*if aar ge 2009 then delete;
*run;

data out.alk_level7;
set aglg13c;* aglg13d;
if maxp ge minp and minp gt 0.00001 then delete;
if age=0 and maxp gt 0.9999 then delete;
if sums lt 50 and prange gt 0.5 then delete;
*if aar ge 2009 and sums lt 50 and prange gt 0.5 then delete;
pi=n/s;
level=1;
keep age geartype aar month2 NS  maxp minp prange 
level pred lower upper n s maxscm minscm scm pi;
run;


*******  The dataset aglg12 contains the predicted pi's ('pred')           ***********
*******   along with the 95% CL of this prediction ('lower' and 'upper') ***********
*******  as well as the factors in the model and various other           ***********
*******  parameters                                                      ***********;

*Plots of predictions and observed pi's ;
/*

proc sort data=out.alk_level7 out=t1;
by  age geartype aar NS month2 scm;
run;

data t2;
set t1;
if maxscm lt 18 and scm gt maxscm+2 then pred=0;
if maxscm=19 and scm gt maxscm+3 then pred=0;
if maxscm gt 19 and scm gt maxscm+4 then pred=0;
if minscm lt 20 and scm lt minscm-2 then pred=1;
if minscm=22 and scm lt minscm-3 then pred=1;
if minscm ge 24 and scm lt minscm-4 then pred=1;
run;

title ' ';

proc gplot data=t2;
plot (pi pred lower upper)*scm/overlay; *pred er den prediktede værdi af pi eller n/s;
by age geartype aar NS  month2;
symbol1 v=plus i=none c=bl;
symbol2 v=none i=join l=1 c=bl;
symbol3 v=none i=spline l=2 c=bl;
symbol4 v=none i=spline l=2 c=bl;
title1 'plot af data=t2 - plot (pi pred lower upper)*scm/overlay';
run;
/*
title ' ';

proc gplot data=t2;
plot pred*scm=month;
by age geartype aar;
symbol1 v=plus i=join c=blue;
symbol2 v=plus i=join c=red;
symbol3 v=plus i=join c=green;
symbol4 v=plus i=join c=orange;
symbol5 v=plus i=join c=brown;
symbol6 v=plus i=join c=red;
title1 'plot af data=t2 - plot pred*scm=surv_loc_new';
run;
quit;
*/
