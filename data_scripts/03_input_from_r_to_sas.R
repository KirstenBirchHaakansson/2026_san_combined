
library(tidyverse)
library(ggplot2)

path_in <- "./data/"
path_out <- "./data/"

area_file <- read.csv(paste0("./boot/data/references/list_areas.csv"))
names(area_file)

# Input to ALK ----

alk <- readRDS(paste0(path_in, "rdb_ca_all_with_age.rds"))
hh <- readRDS(paste0(path_in, "rdb_hh_all.rds"))

alk <- left_join(alk, select(hh, -recType), by = c("sampType", "landCtry", "vslFlgCtry", "year", "proj", "trpCode", "staNum"))

unique(is.na(alk$date))

alk_no_date <- subset(alk, is.na(date))

alk$aar <- alk$year
alk$month <- alk$month
alk$day <- lubridate::day(alk$date)

unique(alk$day)

alk$art[alk$sppName == "Ammodytes marinus"] <- "TBM"
alk$art[alk$sppName == "Ammodytes tobianus"] <- "TBT"
alk$intsq <- alk$rect.x

unique(alk$intsq)

alk$scm <- alk$lenCls/10
unique(alk$scm)

alk_1 <- left_join(alk, area_file, by = c("intsq" = "square"))

alk_1$no <- 1

alk_2 <- summarise(group_by(alk_1, aar, landCtry, vslFlgCtry, proj, trpCode, staNum, month, day, art, intsq, PP_ar_tx, scm, age),
                   no = sum(no))

alk_3 <- subset(alk_2, age < 12)
alk_3$age <- paste0("a", alk_3$age)

test <- distinct(ungroup(alk_2), aar, vslFlgCtry)

## transpose

alk_t <- spread(alk_3, key = age, value = no, fill = 0)

## Output

write.csv(alk_t, paste0(path_out, "input_sas_alk.csv"), row.names = F)

## LD
ld <- readRDS(paste0(path_in, "rdb_hl_all.rds"))
hh <- readRDS(paste0(path_in, "rdb_hh_all.rds"))
ca <- readRDS(paste0(path_in, "rdb_ca_all.rds"))

ld <- left_join(ld, select(hh, -recType), by = c("sampType", "landCtry", "vslFlgCtry", "year", "proj", "trpCode", "staNum"))

unique(is.na(ld$date))

ld_no_date <- subset(ld, is.na(date))

ld$aar <- ld$year
ld$month <- lubridate::month(ld$date)
ld$day <- lubridate::day(ld$date)

unique(ld$day)

ld$julday <- lubridate::yday(ld$date)
unique(ld$julday)

ld$cruise <- ld$proj
ld$trip <- ld$trpCode
ld$stat <- ld$staNum

unique(ld$sppName)
ld$art[ld$sppName == "Ammodytes marinus"] <- "TBM"
ld$art[ld$sppName == "Ammodytes tobianus"] <- "TBT"
unique(ld$art)

ld$intsq <- ld$rect

unique(ld$intsq)
no_sq <- subset(ld, intsq == "")
hist(no_sq$year, breaks = c(2023, 2024))
hist(ld$year, breaks = c(2023, 2024))

ld$scm <- floor((ld$lenCls/10)*2)/2
unique(ld$scm)

spec_id <- distinct(ld, cruise, trip, stat)
spec_id <- mutate(spec_id, spec_id = row.names(spec_id))

ld_0 <- left_join(ld, spec_id)

ld_1 <- left_join(ld_0, area_file, by = c("intsq" = "square"))

ld_2 <- summarise(group_by(ld_1, aar, landCtry, vslFlgCtry, spec_id, cruise, trip, stat, month, julday, day, art, intsq, PP_ar_tx, scm),
                   lenNum = sum(lenNum))

st_antal <- summarise(group_by(ld_2, aar, landCtry, vslFlgCtry, spec_id, cruise, trip, stat),
                      st_antal = sum(lenNum))

ld_3 <- left_join(ld_2, st_antal)

# Add mean weights ----
ca <- readRDS(paste0(path_in, "rdb_ca_all.rds"))

ca$scm <- floor((ca$lenCls/10)*2)/2
unique(ca$indWt)
ca$indWt <- ca$indWt/1000

ca$trip <- as.integer(ca$trpCode)

test <- distinct(ca, year, proj, trpCode, staNum, trip)

# ggplot(subset(ca, year == 1997 & proj == "DNK-IN-HIRT"), aes(x = lenCls, y = indWt, col = paste(trpCode))) +
#   geom_boxplot()

# ggplot(subset(ca, year == 1999 & proj == "DNK-2132"), aes(x = lenCls, y = indWt, col = paste(trip, staNum))) +
#   geom_boxplot()

ca$indWt[ca$year %in% c(1997) &
           ca$proj == "DNK-IN-HIRT" &
           ca$trip > 7000] <-
  ca$indWt[ca$year %in% c(1997) &
             ca$proj == "DNK-IN-HIRT" & ca$trip > 7000] / 100

dat_1999 <- subset(ca, year == 1998 & proj == "NOR-sandeel")

ggplot(subset(dat_1999, year == 1998 & proj == "NOR-sandeel"), aes(x = lenCls, y = indWt, col = paste0(trpCode))) +
  geom_point() # 1999 not ok

# ca$indWt[ca$year %in% c(1999) &
#            ca$proj == "DNK-2132"] <- ca$indWt[ca$year %in% c(1999) &
#                                            ca$proj == "DNK-2132"]/100

ggplot(subset(ca, year == 1999 & proj == "DNK-2132"), aes(x = lenCls, y = indWt, col = paste0(trpCode, staNum))) +
  geom_point()


mw <- summarise(group_by(ca, year, proj, trpCode, staNum, scm), mw = mean(indWt, na.rm = T))

ggplot(subset(mw, year >= 1983 & year < 1988), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # 1993 not ok - fixed
ggplot(subset(mw, year >= 1988 & year < 1993), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok
ggplot(subset(mw, year >= 1993 & year < 1998), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # 1997 not ok
ggplot(subset(mw, year >= 1998 & year < 2003), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # 1999 not ok
ggplot(subset(mw, year >= 2003 & year < 2008), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok
ggplot(subset(mw, year >= 2008 & year < 2013), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok
ggplot(subset(mw, year >= 2013 & year < 2018), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok
ggplot(subset(mw, year >= 2018 & year < 2023), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok
ggplot(subset(mw, year >= 2023 & year < 2028), aes(x = scm, y = mw, col = paste0(year, proj))) +
  geom_point() # ok

ggplot(subset(mw), aes(x = scm, y = mw, col = as.character(year))) +
  geom_point() # ok

mw <- mutate(mw, mw_exp = 0.0000025*(scm)^3.068)

mw_1 <- subset(mw, scm >= 2 & scm <= 30)

mw_1 <- mutate(mw_1, vgt_dif=(mw-mw_exp)/mw_exp)

hist(mw_1$vgt_dif)

mw_1 <- mutate(mw_1, mark = ifelse(vgt_dif >= -0.75 & vgt_dif <= 0.75, "ok", "outlier" ))

nrow(subset(mw_1, mark == "outlier")) * 100 / nrow(mw_1)

ggplot(mw_1, aes(x = scm, y = mw, col = mark)) +
  geom_point() +
  geom_line(aes(x = scm, y = mw_exp, col = "red")) +
  facet_wrap(~year)

mw$cruise <- mw$proj
mw$trip <- mw$trpCode
mw$stat <- mw$staNum
mw$aar <- mw$year

ld_4 <- left_join(ld_3, mw)
test <- subset(ld_4, is.na(mw) & year >= 1997)
ld_4 <- mutate(ld_4, vgt = mw * lenNum)
test_2 <- subset(ld_4, is.na(vgt) & year >= 1997)

no_mw <- subset(ld_4, is.na(mw) | is.na(vgt) | is.na(year))
no_mw <- subset(no_mw, !(cruise == "NOR-sandeel" & aar < 1997))
no_mw <- subset(no_mw, !(cruise %in%  c("DNK-SEAS03", "DNK-SEAS", "DNK-MON")))

hist(no_mw$aar, breaks = 40)

ld_4$m_vgt <- ld_4$mw
ld_4$vgt_exp <- ld_4$mw_exp
ld_4$antal <- ld_4$lenNum

ld_done <- select(ld_4, aar, landCtry, vslFlgCtry, spec_id, cruise, trip, stat, month, julday, day, art, intsq, PP_ar_tx, scm, antal, st_antal,
                  vgt, m_vgt, vgt_exp)


test <- subset(ld_done, is.na(m_vgt))
test <- subset(test, !(cruise == "NOR-sandeel" & aar < 1997))
test <- subset(test, !(cruise %in%  c("DNK-SEAS03", "DNK-SEAS")))

test_nor <- subset(ld_done, (cruise == "NOR-sandeel" & aar > 1997) & !(is.na(m_vgt)))

# Output

write.csv(ld_done, paste0(path_out, "input_sas_ld.csv"), row.names = F, na = "")
