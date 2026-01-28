

# Update official catches area 4 and 3a - from 2022 including 3a

library(haven)
library(tidyr)
library(stringr)
library(dplyr)
library(RColorBrewer)

path_data <- "Q:/mynd/Assessement_discard_and_the_like/assessment_scripts/HAWG_sandeel/2022/WKSANDEEL/input/"

# Old ----
old <- read.csv(paste0(path_data, "/HistoricalLandings1950-2010/ICES_1950-2010.csv"))

head(old)
spp <- distinct(old, Species)

old_1 <- subset(old, Species == "Sandeels(=Sandlances) nei")

unique(old_1$Division)

old_2 <- subset(old_1, Division %in% c("III a", "IV (not specified)", "IV a",
                                       "IV a+b (not specified)", "IV b", "IV c", 
                                       "IIIa  and  IVa+b  (not specified)"))
names(old_2)

old_3 <- gather(old_2, key = Year, -Species, -Division, -Country, value = ton)
old_3$ton <- as.numeric(old_3$ton)

tjek_sum <- summarise(group_by(old_3, Year, Division), ton = sum(ton, na.rm = T))

old_3 <- mutate(old_3, Year = as.integer(str_remove(Year, "X")), Species = "Ammodytes", Source = "ICES_1950-2010")

head(old_3)

unique(old_3$Country)

old_3$Country[old_3$Country == "Faeroe Islands"] <- "Faroes"
old_3$Country[old_3$Country == "Germany, Fed. Rep. of"] <- "Germany"
old_3$Country[old_3$Country %in% c("UK - Eng+Wales+N.Irl.", "UK - England & Wales", "UK - Scotland")] <- "UK"

unique(old_3$Division)

old_3$Area[old_3$Division %in% c("III a")] <- "27.3.a"
old_3$Area[old_3$Division %in% c("IV (not specified)", "IV a", "IV a+b (not specified)", 
                                 "IV b", "IV c")] <- "27.4"
old_3$Area[old_3$Division %in% c("IIIa  and  IVa+b  (not specified)")] <- "27.3.a, 27.4.a"

old_4 <- summarise(group_by(old_3, Year, Species, Area, Country, Source), ton = sum(ton, na.rm = T))

old_5 <- spread(old_4, key = Country, value = ton, fill = 0)

unique(old_4$Year)

# Mid ----
mid <- subset(read.csv(paste0(path_data, "ICESCatchDataset2006-2019.csv")), Species %in% c("SAN", "ABZ"))
head(mid)

unique(mid$Area)
unique(mid$Country)

mid_1 <- subset(mid, Area == "27.4" | Area == "27.3.a")

mid_2 <- gather(mid_1, key = Year, -Species, -Area, -Units, -Country, value = ton)
mid_2$ton <- as.numeric(mid_2$ton)

mid_2 <- mutate(mid_2, Year = str_remove(Year, "X"), Species = "Ammodytes", Source = "ICESCatchDataset2006-2019")

mid_3 <- summarise(group_by(mid_2, Year, Species, Area, Country, Source), ton = sum(ton, na.rm = T))

head(mid_3)

# Pre ----

pre_san <- subset(read.csv(paste0(path_data, "2020preliminaryCatchStatistics.csv"), header = F), substr(V3, 1, 4) == "Ammo")
head(pre_san)

pre_san <- select(pre_san, V1, V3, V4, V5, V6)
head(pre_san)

colnames(pre_san) <- c("Year", "Species", "Area", "Country", "ton")
head(pre_san)

str(pre_san)

pre_san$ton <- as.numeric(pre_san$ton)

unique(pre_san$Area)

pre_san_1 <- subset(pre_san, Area %in%  c("27_4_A", "27_4_B", "27_4_C", "27_3_A", "27_3_A_20", "27_3_A_21"))
pre_san_1 <- mutate(pre_san_1, Source = "2020preliminaryCatchStatistics")

pre_san_1$Area[pre_san_1$Area %in% c("27_4_A", "27_4_B", "27_4_C")] <- "27.4"
pre_san_1$Area[pre_san_1$Area %in% c("27_3_A", "27_3_A_20", "27_3_A_21")] <- "27.3.a"

pre_san_2 <- summarise(group_by(pre_san_1, Year, Species, Area, Country, Source), ton = sum(ton))

# Last year ----
path_out <- "M:/Tobis/Tobis_assessment/SMS_2022/Data/catch/"
year <- 2021
last <- read.csv(paste(path_out, "catch_year_month_square_", year, ".csv", sep = ""))
head(last)

list_areas <- read.csv("Q://dfad//users//anbes//home//Data//Sandeel//csv//list_areas.csv")

last_1 <- left_join(last, list_areas, by = c("Square" = "square"))

last_1 <- mutate(last_1, Area = ifelse(PP_ar_tx %in% c('3AS','3AN'), '27.3.a', 
                                        ifelse(PP_ar_tx %in% c('1A','1B','1C','2A','2B','2C','3','4','5','6','SH'), '27.4', NA)),
                 Source = "HAWG members")
head(last_1)

last_2 <- subset(last_1, Year == 2021 & Area %in% c("27.3.a", "27.4"))
last_3 <- summarise(group_by(last_2, Year, Area, Country, Source), ton = sum(Weight))

last_3$Year <- as.numeric(last_3$Year)

last_3$Country[last_3$Country == "DEN"] <- "Denmark"
last_3$Country[last_3$Country == "GER"] <- "Germany"
last_3$Country[last_3$Country == "NOR"] <- "Norway"
last_3$Country[last_3$Country == "SCO"] <- "UK"
last_3$Country[last_3$Country == "SWE"] <- "Sweden"

# Combine ----
unique(mid_3$Year)
unique(pre_san_2$Year)

new <- bind_rows(mid_3, pre_san_2)
new$Year <- as.numeric(new$Year)

new$Country[new$Country == "DK"] <- "Denmark"
new$Country[new$Country == "DE"] <- "Germany"
new$Country[new$Country == "FO"] <- "Faroes"
new$Country[new$Country == "IE"] <- "Ireland"
new$Country[new$Country == "NL"] <- "Netherlands"
new$Country[new$Country == "NO"] <- "Norway"
new$Country[new$Country == "SE"] <- "Sweden"
new$Country[new$Country == "GB"] <- "UK"
new$Country[new$Country == "LT"] <- "Lithuania"
new$Country[new$Country == "FR"] <- "France"

new_2 <- bind_rows(new, last_3)

new_t <- spread(new_2, key = Country, value = ton, fill = 0)

# new_t$Total <- rowSums(new_t[, c(5:ncol(new_t))])

unique(old_5$Year)
final <- bind_rows(subset(old_5, Year < 2006), new_t)

final$Ireland[is.na(final$Ireland)] <- 0
final$Total <- rowSums(final[, c(5:ncol(final))])

final$Species <- "Ammodytes"

write.csv(final, paste0("Q:/mynd/Assessement_discard_and_the_like/assessment_scripts/HAWG_sandeel/2022/WKSANDEEL/input/official_landings_3a4abc_new.csv"),
          row.names = F)

final_t <- gather(final, key = Country, -Year, -Source, -Species, -Area, value = ton)

final_t$Country[final_t$Country == "FR"] <- "France"

write.csv(final_t, paste0("Q:/mynd/Assessement_discard_and_the_like/assessment_scripts/HAWG_sandeel/2022/WKSANDEEL/input/official_landings_3a4abc_new_t.csv"),
          row.names = F)
