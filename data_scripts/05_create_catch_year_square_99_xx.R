library(tidyverse)
library(ggplot2)
library(readxl)

options(scipen = 999)

# scenario <- "WKSAND16"

path_in <- "./data/"
path_out <- "./data/"
path_ref <- "./boot/data/references/"


new_timeseries_start <- 99
new_timeseries_end <- 25

dat <- read.csv(paste0(path_in, "catch_year_ctry_month_square_99_", new_timeseries_end, ".csv"), sep = ";")
names(dat)

dat_sum <- summarise(group_by(dat, Year, Square), ton = sum(Weight, na.rm = T))


write.table(dat_sum, paste0(path_out, "catch_year_square_99_", new_timeseries_end, ".csv"), sep = ";", row.names = F)

dat_sum_year <- summarise(group_by(dat, Year), ton = sum(Weight, na.rm = T))

