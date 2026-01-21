
Sys.getlocale() # This only runs if not Danish LC-TIME due to month e.g. st_date = as.POSIXlt(sttime, format="%d%B%y:%H:%M")


version <- "2025"

season <- 2

ncores=8 #number of cores to use on this computer for parallel computing

#location of Danish files including tbs_99_logdata.csv
dandatdir = "C:/Users/kibi/OneDrive - Danmarks Tekniske Universitet/stock_coord_work/san/2026_san_combined/boot/data/Effort/" 

#location of Norwegian files including catch_byVessel_byDay_2011.csv
nordatdir = "C:/Users/kibi/OneDrive - Danmarks Tekniske Universitet/stock_coord_work/san/2026_san_combined/boot/data/Effort/" 

path_common <- "C:/Users/kibi/OneDrive - Danmarks Tekniske Universitet/stock_coord_work/san/2026_san_combined/model/"

scenario <- "WKSAND16"

outputdir <- path_common

# last year of Danish data
danlastyear=25 #last 2 digits. 21 means 2021.

#last year of Norwegian data
norlastyear = 2024 # 4 digits

#file names (without .txt) that define which squares belong to which areas
#note "99A9" and ".A9" are excluded in the processing below

areadir <- "C:/Users/kibi/OneDrive - Danmarks Tekniske Universitet/stock_coord_work/san/2026_san_combined/boot/data/references/"
#areafiles=c("square_to_areas_2015", "square_to_areas_test")
areafiles=c("square_to_sandeel_areas_WKSAND16")
# ,
# 					"square_to_sandeel_areas_WKSAND22a",
# 					"square_to_sandeel_areas_WKSAND22b")

# areafiles=c("square_to_sandeel_areas_WKSAND16")

#DO NOT CHANGE BELOW THIS LINE
## ----libs--------------------------------------------------------------------------------------
library(glmmTMB)
library(plyr)
library(doParallel)
library(ggplot2); theme_set(theme_bw())
library(lubridate)

#Snow-like parallelization so it runs on Windows as well as Unix-like computers
cl = makeCluster(ncores)
registerDoParallel(cl)


## ----dat---------------------------------------------------------------------------------------
#Danish data

# setwd(dandatdir)

tmp = c(82:99, paste0("0", 0:9), 10:danlastyear) #numbers in tbs file names

x0 = do.call(rbind, lapply(tmp, function(i){
  x00 = read.csv(paste0(dandatdir, "tbs_", i, "_logdata.csv"))
  names(x00)=tolower(names(x00))
  return(x00)
}))

(oldnames <- names(x0))
names(x0)=c("fid","lognr","year","month","grt_int","gear","spec","fvd","ices_txt","sttime",
            "endtime","hours_absent","kwmax","yield","days_trip","days","cpue")
x00=x0 #save in case something goes wrong

ddply(x0, ~year, summarize, 
      lmid = mean(nchar(sttime)),
      llo = min(nchar(sttime)),
      lhi = max(nchar(sttime))
)
#7 chars 1982-1989 (date without time)
#10 chars 1990-1999 (hour was added)
#13 chars 2000-2021 (minutes were added)
x0[x0$year<1990,]$sttime = paste0(x0[x0$year<1990,]$sttime, ":00")
x0[x0$year<2000,]$sttime = paste0(x0[x0$year<2000,]$sttime, ":00")

ddply(x0, ~year, summarize, 
      lmid = mean(nchar(endtime)),
      llo = min(nchar(endtime)),
      lhi = max(nchar(endtime))
)			
#no end time before 1985
#7 chars 1985-1989
#10 chars 1990-1999
#13 chars 2000-2021

x0[x0$year<1990,]$endtime = paste0(x0[x0$year<1990,]$endtime, ":00")
x0[x0$year<2000,]$endtime = paste0(x0[x0$year<2000,]$endtime, ":00")

x1 = transform(x0,
               days_absent=ceiling(hours_absent/24),
               yield=yield/1000,
               cpue=cpue/1000,
               st_date = as.POSIXlt(sttime, format="%d%B%y:%H:%M"),
               end_date = as.POSIXlt(endtime, format="%d%B%y:%H:%M"),
               square=ices_txt,
               loc=regexpr("-", grt_int)
)


test <- dplyr::distinct(x1, sttime, st_date, endtime, end_date)

# fill in missing start dates from end dates and trip duration
x1.1=transform(x1, 
               st_date = as.Date(st_date),
               end_date=as.Date(end_date)
)

x1.1[is.na(x1$st_date),]$st_date = x1.1[is.na(x1$st_date),]$end_date
x1.1[is.na(x1$st_date),]$st_date = x1.1[is.na(x1$st_date),]$st_date - x1.1[is.na(x1$st_date),]$days_trip

x2 = transform(x1.1,
               fishjulday = as.POSIXlt(st_date)$yday,
               tripdur = end_date-st_date,
               grtmin=as.numeric(substr(grt_int,1,loc-1)),
               grtmax=as.numeric(substr(grt_int,loc+1,nchar(grt_int))),
               # month=month(as.POSIXlt(st_date)), # Kibi - using month from log file as Anna does (that one is based on catch date)
               country="DEN"
)			

unique(x2$year)

#Norwegian data

# setwd(nordatdir)

n0 = do.call(rbind, lapply(2011:norlastyear, function(y){
  x00 = read.csv(paste0(nordatdir, "catch_byVessel_byDay_", y, ".csv"))
  names(x00)=tolower(names(x00))
  return(x00)
}))

n1 = transform(n0, 
               date=as.Date(date),
               country='NOR',
               fid='NOR',
               yield=catch_ton,
               cpue = catch_ton,
               square = icessq,
               days_trip=1,
               loc=regexpr("-", vesselsize)
)

n2= transform(n1, 
              year = as.numeric(substr(date, 1,4)),
              month = as.numeric(substr(date,6,7)),
              day = as.numeric(substr(date, 9,10)),
              fishjulday=julian(date),
              grtmin=as.numeric(substr(vesselsize,1,loc-1)),
              grtmax=as.numeric(substr(vesselsize,loc+1,nchar(vesselsize)))
)

v1 = c("fid", "year", "month", "cpue","days_trip","square","fishjulday" ,"grtmin","grtmax", "country", "yield")
dn2=rbind(x2[,v1], n2[,v1])

x3 = transform(dn2,
               #x3 = transform(x2[,v1],
               fishweek = ifelse(floor(fishjulday/7)==fishjulday/7, fishjulday/7, floor(fishjulday/7)+1),
               grtmin=ifelse(grtmin!=9999, grtmin, NA),
               grtmax=ifelse(grtmax!=9999, grtmax, NA),
               season = ifelse(month<7, 1, 2)#half year
)

if (season == 2) {
  x3$season = ifelse(x3$month<7, 1, 2)
} else if (season == 3) {
  x3$season[x3$month %in% c(1, 2, 3, 4)] = 1
  x3$season[x3$month %in% c(5, 6, 7, 8)] = 2
  x3$season[x3$month %in% c(9, 10, 11, 12)] = 3
  
} else {
  
  Print("Season not implemented")
}

x4 = transform(x3, 
               julw=ifelse(!is.na(fishweek), fishweek, round(fishjulday,7)/7),
               grtmean=(grtmin+grtmax)/2,
               grt_num=(grtmin+grtmax)/2,
               dec = ifelse(year<=1988, 1, ifelse(year<=1998, 2, ifelse(year<=2005, 3, 4)))
)
dat=subset(x4, !square %in% c("99A9", ".A9"))

# # Test missing areas - kibi
# sq = read.csv(paste0(areadir, i,".csv"))
# #	sq = read.delim(paste0(areadir, i,".txt"))
# names(sq)=tolower(names(sq))
# test <- join(dat, sq, type = "left")
# test_sum <- ddply(test, ~year+hy+area+country, summarize,
#               eff_catch=sum(yield)
# )

vars = c("year","month","julw","fid","cpue","grtmean","days_trip","season","square", "yield")
#vars = c("dec","year","month","julw","fid","cpue","grtmean","days_trip","season","square", "yield")
dat2=na.omit(dat[,vars])

#change zero cpue obs
#dat2[which(dat2$cpue==0), "cpue"]=0.0001
dat2=subset(dat2, cpue>0)

## ----split the data by year
ysdat = split(dat2, dat2$year)

# do a test model on one year
i="2014"
tmp=ysdat[[i]]
m2 = glmmTMB(log(cpue) ~ 
               (1|julw:square) +(1|fid) + log(I(grtmean/200)), tmp)
unname(fixef(m2)$cond["log(I(grtmean/200))"])


FUN = function(tmp){
  library(glmmTMB)
  m2 = glmmTMB(log(cpue) ~ 
                 (1|julw:square) +(1|fid) + log(I(grtmean/200)), tmp)
  unname(fixef(m2)$cond["log(I(grtmean/200))"])
}

## ----model cpue for all years 
## ----cpue (Mixed annual month)-------------------------------------------------------------------------------------
b5 = foreach(i= names(ysdat)) %dopar% FUN(ysdat[[i]])

stopCluster(cl)

res = data.frame(
  b = unlist(b5), 
  year = as.numeric(names(ysdat))
)


## ----standardize-------------------------------------------------------------------------------

dat3 = join(dat2, res, by="year")#, type="full")

dat4 = transform(dat3, newE=days_trip*(grtmean/200)^b)

# Do the standardization for each version of the areas

for(i in areafiles){ #not too slow so no need to parallel
  
  sq = read.csv(paste0(areadir, i,".csv"))
  #	sq = read.delim(paste0(areadir, i,".txt"))
  names(sq)=tolower(names(sq))
  
  # sq$area <- gsub("r", "", sq$area)
  
  
  ton <-
    read.csv(paste0(
      outputdir, substr(i, 25, 35),
      "/Total_catch_per_year_area.csv"
    ))
  
  
  # test <- join(dat4, sq, type = "left")
  # test_1 <- join(dat4, sq)
  
  stanE = ddply(join(dat4, sq), ~year+season+area, summarize,
                E = sum(newE, na.rm = TRUE),
                eff_catch=sum(yield),
                model="Mixed Annual Weekly"
  )
  
  sumsE = ddply(join(dat2, sq), ~year+season+area, summarize,
                E = sum(days_trip, na.rm = TRUE),
                eff_catch=sum(yield),
                model="Summed days"
  )
  
  stanE2 = join(ton, rbind(sumsE, stanE), type = "left")
  
  stanE2=transform(stanE2, newE = E*ton/eff_catch)
  stanE2$scale <- stanE2$ton/stanE2$eff_catch
  
  write.csv(stanE2, file=paste0(outputdir, substr(i, 25, 35), "/Standardized_effort_days_", version, ".csv"))
  
  ggplot(subset(stanE2, !is.na(area)), aes(year, newE, group=model))+geom_line(aes(colour=model))+
    ylab("Standardized effort days") +
    scale_color_manual(values = c("#1170aa", "#c85200")) +
    facet_grid(area~season, labeller = label_both)+
    labs(color=NULL, subtitle = i, title = "Standardized effort")+
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5)) + 
    theme(legend.position="bottom")
  
  
  ggsave(
    paste0(
      outputdir, substr(i, 25, 35),"/Standardized_effort_days_",
      version,
      ".png"
    ),
    height = 8,
    width = 6
  )
  
  
  ggplot(subset(stanE2, !is.na(area)), aes(year, ton/eff_catch, group=model))+geom_line(aes(colour=model))+
    facet_grid(area~season, labeller = label_both, scales = "free")+
    scale_color_manual(values = c("#1170aa", "#c85200")) + 
    labs(color=NULL, subtitle = i, title = "Multiplier for scaling effort to total landings")+
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5)) + theme(legend.position = "none")
  
  
  ggsave(
    paste0(
      outputdir, substr(i, 25, 35),
      "/Scaling_effort_to_total_landings_",
      version,
      ".png"
    ),
    height = 8,
    width = 6
  )
  
  stanE2$model[is.na(stanE2$newE) & stanE2$ton > 0 & is.na(stanE2$model)] <- "Landings, no effort"
  stanE2$model[is.na(stanE2$newE) & stanE2$ton == 0 & is.na(stanE2$model)] <- "No landings, no effort"
  
  is.na(stanE2$newE) <- 0
  
  ggplot(subset(stanE2, !is.na(area)), aes(year, model, group=model))+geom_point(aes(colour=model))+
    facet_grid(area~season, labeller = label_both, scales = "free_y")+
    scale_color_manual(values = c("#1170aa", "#c85200", "#fc7d0b", "#a3acb9")) + 
    labs(color=NULL, subtitle = i, title = "Landings vs. effort - completness")+
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5)) + theme(legend.position = "none")
  
  
  ggsave(
    paste0(
      outputdir, substr(i, 25, 35),
      "/Landings_vs_effort_completnesss_",
      version,
      ".png"
    ),
    height = 8,
    width = 6
  )
  
  
  ggplot(subset(stanE2, !is.na(area) & model == "Landings, no effort"), aes(year, ton, group=model))+geom_point(aes(colour=model))+
    facet_grid(area~season, labeller = label_both, scales = "free_y")+
    scale_color_manual(values = c("#1170aa", "#c85200", "#fc7d0b", "#a3acb9")) + 
    labs(color=NULL, subtitle = i, title = "Ton, when landings, but no effort")+
    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=0.5)) + theme(legend.position = "none")
  
  
  ggsave(
    paste0(
      outputdir, substr(i, 25, 35),
      "/Landings_no_effort_ton_",
      version,
      ".png"
    ),
    height = 8,
    width = 6
  )
}
