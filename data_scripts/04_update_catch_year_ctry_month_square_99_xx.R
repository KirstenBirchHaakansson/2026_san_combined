

library(tidyverse)
library(ggplot2)
library(readxl)

options(scipen = 999)

path_in_this_year <- "./boot/data/"
path_in_last_year <- "./boot/data/outputs_from_last_year/"
path_out <- "./data/"
path_ref <- "./boot/data/references/"

old_timeseries_end <- 24

new_timeseries_start <- 99
new_timeseries_end <- 25


area_file <- read.csv(paste0(path_ref, "ICES_StatRec_mapto_ICES_Areas 2021.csv"))
names(area_file)

old <- read.csv(paste0(path_in_last_year, "catch_year_ctry_month_square_99_", old_timeseries_end, ".csv"), sep = ";")

old_org <- old # For comparing

unique(old$Country)

old$id <- row.names(old)

names(old)

unique(old$source)
unique(old$update_date)

# GER ----

de_new <- readxl::read_xlsx(paste0(path_in_this_year, "Annex_1_HAWG_sandeel_exchange_format_v2024_DE_2025.xlsx"))
head(de_new)
de_new <- de_new[c(2:nrow(de_new)), ]
unique(de_new$year)
de_new$weight <- as.numeric(de_new$weight)

de_new$vesselFlagCountry <- "GER"
de_new$Country <- de_new$vesselFlagCountry
de_new$Year <- de_new$year
de_new$Month <- de_new$month
de_new$Square <- de_new$statisticalRectangle
de_new$Weight <- de_new$weight

de_out <- subset(old, Country == "GER" & (Year %in% de_new$year))
old <- subset(old, !(id %in% de_out$id))

old <- bind_rows(old, de_new)

# ENG ----
uk_new <- readxl::read_xlsx(paste0(path_in_this_year, "Annex_1_HAWG_sandeel_exchange_format_UK_EW_2025.xlsx"))
head(uk_new)
uk_new <- uk_new[c(2:nrow(uk_new)), ]
unique(uk_new$year)
uk_new$weight <- as.numeric(uk_new$weight)

uk_new$vesselFlagCountry <- "ENG"
uk_new$Country <- uk_new$vesselFlagCountry
uk_new$Year <- uk_new$year
uk_new$Month <- uk_new$month
uk_new$Square <- uk_new$statisticalRectangle
uk_new$Weight <- uk_new$weight

uk_out <- subset(old, Country == "ENG" & (Year %in% uk_new$year))
old <- subset(old, !(id %in% uk_out$id))

old <- bind_rows(old, uk_new)


# SWE ----
se_new <- read.delim(paste0(path_in_this_year, "Annex_1_HAWG_sandeel_exchange_format_SWE_2024-2025.txt"))
head(se_new)
unique(se_new$year)
se_new$weight <- as.numeric(se_new$weight)

se_new$vesselFlagCountry <- "SWE"
se_new$Country <- se_new$vesselFlagCountry
se_new$Year <- se_new$year
se_new$Month <- se_new$month
se_new$Square <- se_new$statisticalRectangle
se_new$Weight <- se_new$weight

unique(se_new$statisticalRectangle)
unique(se_new$vesselFlagCountry)

se_out <- subset(old, Country == "SWE" & (Year %in% se_new$year))
old <- subset(old, !(id %in% se_out$id))

old <- bind_rows(old, se_new)


# LTU ---- # None in 2024
# lu <- readxl::read_xlsx(paste0(path_in, "Annex_1_HAWG_sandeel_landings_data_LT.xlsx"))
# 
# unique(lu$statisticalRectangle)
# unique(lu$vesselFlagCountry)
# 
# lu_done <- summarise(group_by(lu, vesselFlagCountry, year, month, statisticalRectangle), weight = sum(weight, na.rm = T))

# DNK ----

dk_new <- read.csv(paste0(path_in_this_year, "Annex_1_HAWG_sandeel_exchange_format_DNK.csv"))
head(dk_new)
unique(dk_new$year)
dk_new$weight <- as.numeric(dk_new$weight)

dk_new$vesselFlagCountry <- "DEN"
dk_new$Country <- dk_new$vesselFlagCountry
dk_new$Year <- dk_new$year
dk_new$Month <- dk_new$month
dk_new$Square <- dk_new$statisticalRectangle
dk_new$Weight <- dk_new$weight/1000

unique(dk_new$statisticalRectangle)
unique(dk_new$vesselFlagCountry)

dk_out <- subset(old, Country == "DEN" & (Year %in% dk_new$year))
old <- subset(old, !(id %in% dk_out$id))

old <- bind_rows(old, dk_new)

# NOR ----
# no_new <- read.csv(paste0(path_in_this_year, "Annex_1_HAWG_sandeel_exchange_format_Norway_Table1.csv"))
# head(no_new)
# unique(no_new$year)
# no_new$weight <- as.numeric(no_new$weight)
# 
# unique(no_new$area)
# no_new$area[no_new$area == "27.4b"] <- "27.4.b"
# 
# no_new$vesselFlagCountry <- "NOR"
# no_new$Country <- no_new$vesselFlagCountry
# no_new$Year <- no_new$year
# no_new$Month <- no_new$month
# no_new$Square <- no_new$statisticalRectangle
# no_new$Weight <- no_new$weight/1000
# 
# 
# unique(no_new$statisticalRectangle)
# unique(no_new$vesselFlagCountry)
# 
# no_out <- subset(old, Country == "NOR" & (Year %in% no_new$year))
# old <- subset(old, !(id %in% no_out$id))
# 
# old <- bind_rows(old, no_new)

# Test 2024 ----

dat_2024 <- subset(old, Year == 2024 & area %in% c("27.4.c", "27.4b", "27.4.b", "27.4.a", "27.3.a.20", "27.3.a.21"))

dat_2024_sum <- summarise(group_by(dat_2024, Year, Country), w = sum(Weight, na.rm = T))

# Test 2025 ----

dat_2025 <- subset(old, Year == 2025 & area %in% c("27.4.c", "27.4b", "27.4.b", "27.4.a", "27.3.a.20", "27.3.a.21"))

dat_2025_sum <- summarise(group_by(dat_2025, Year, Country), w = sum(Weight, na.rm = T))

# Combine


done <- old

done$source <- "Data submitted to HAWG"
done$update_date <- "2024-01-14"

done_final <- left_join(done, select(area_file, ICESNAME, Area_27), by = c("Square" = "ICESNAME"))

done_final$Area_27 <- paste0("27.", done_final$Area_27 )

done_final$area[is.na(done_final$area)] <- done_final$Area_27[is.na(done_final$area)]

done <- done_final

unique(done$area)

done$area[done$area == "27.4a"] <- "27.4.a"
done$area[done$area == "27.4b"] <- "27.4.b"
done$area[done$area == "27.4c"] <- "27.4.c"

# Compare ----

old_org_sum <- summarise(group_by(old_org, Year, Country), weight_ton_old = sum(Weight, na.rm = T))

done_sum <- summarise(group_by(done, Year, Country), weight_ton_new = sum(Weight, na.rm = T))

comb <- full_join(old_org_sum, done_sum)

comb$diff <- comb$weight_ton_old - comb$weight_ton_new

# Output catch_year_ctry_month_square

write.table(done, paste0(path_out, "catch_year_ctry_month_square_99_", new_timeseries_end, ".csv"), sep = ";", row.names = F)

# 
# done_sum <- summarise(group_by(done, vesselFlagCountry, year, month, statisticalRectangle), weight_ton = sum(weight/1000, na.rm = T))
# 
# old <- read.csv(paste0(path_out, "catch_year_month_square_2021.csv"))
# names(old)
# 
# old_mis <- subset(old, !(Country %in% done_sum$vesselFlagCountry))
# 
# unique(old_mis$Country)
# 
# old_mis$vesselFlagCountry <- old_mis$Country
# old_mis$year <- old_mis$Year
# old_mis$month <- old_mis$Month
# old_mis$statisticalRectangle <- old_mis$Square
# 
# old_sum <- summarise(group_by(old_mis, vesselFlagCountry, year, month, statisticalRectangle), weight_ton = sum(Weight, na.rm = T))
# 
# done_final_0 <- rbind(done_sum, old_sum)
# 
# done_final <- left_join(done_final_0, area_file, by = c("statisticalRectangle" = "square"))
# 
# 
# 
# # Tjek 
# 
# dat_5r_2 <- subset(done_final, Area == 5 & month >= 7)
# 
# dat_6_1 <- subset(done_final, Area == 6 & month < 7)
# 
# dat_6_2 <- subset(done_final, Area == 6 & month >= 7)
# 
# dat_7_1 <- subset(done_final, Area == 7 & month < 7)
# 
# dat_7_2 <- subset(done_final, Area == 7 & month >= 7)
# 
# 
