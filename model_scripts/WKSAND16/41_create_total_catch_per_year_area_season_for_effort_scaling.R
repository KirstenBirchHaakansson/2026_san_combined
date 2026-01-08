

library(dplyr)
# Total landings per area, hy for scaling of effort

path_common <- "./model/"

scenario <- "area16EUUK"

path <- paste0(path_common, scenario, "/")

dat <- read.csv(paste0(path, "catch_in_numbers_and_mw_83_24", ".csv"))

names(dat)

dat$year <- dat$aar
dat$season <- dat$hy

dat_sum <- summarise(group_by(dat, year, season, area), ton = sum(ton, na.rm = T), .groups = "drop")

write.csv(dat_sum, paste0(path, "Total_catch_per_year_area", ".csv"), row.names = F)
