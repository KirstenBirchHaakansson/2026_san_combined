
# Update official catches area 4 and 3a - from 2022 including 3a

library(haven)
library(tidyr)
library(stringr)
library(dplyr)
library(RColorBrewer)

# Years to update
## year-1: data submitted to HAWG
## year-2: data from ICES PreliminaryCatchesFor
## year-3; data from ICES official catch statistic - not implemented

years <- c(2024:2025)

path_out <- "./data/"

##### Update paths and files names below

# Old time series ----
old <- read.csv("./boot/data/outputs_from_last_year/official_landings_3a4abc_52_24.csv", sep = ",")

unique(old$Year)

head(old)

# year-2 Pre ----


pre_san <- subset(
  read.csv(
    "./boot/data/preliminary_catch_statistics/PreliminaryCatchesFor2024.csv",
    header = F,
    sep = ";"
  )
  ,
  substr(V3, 1, 4) == "Ammo"
)
head(pre_san)

pre_san <- select(pre_san, V1, V4, V5, V6, V7)
head(pre_san)

colnames(pre_san) <- c("Year", "Species", "Area", "Country", "ton")
head(pre_san)

str(pre_san)

pre_san$ton <- as.numeric(pre_san$ton)

pre_san$Year <- as.numeric(pre_san$Year)
unique(pre_san$Area)

pre_san_1 <- subset(pre_san, Area %in%  c("27.4.a", "27.4.b", "27.4.c", "27.3.a", "27.3.a.20", "27.3.a.21"))
pre_san_1 <- mutate(pre_san_1, Source = "PreliminaryCatchesFor2024")

pre_san_1$Area[pre_san_1$Area %in% c("27.4.a", "27.4.b", "27.4.Cc")] <- "27.4"
pre_san_1$Area[pre_san_1$Area %in% c("27.3.a", "27.3.a.20", "27.3.a.21")] <- "27.3.a"

pre_san_1$Country[pre_san_1$Country == "DK"] <- "Denmark"
pre_san_1$Country[pre_san_1$Country == "DE"] <- "Germany"
pre_san_1$Country[pre_san_1$Country == "FO"] <- "Faroes"
pre_san_1$Country[pre_san_1$Country == "IE"] <- "Ireland"
pre_san_1$Country[pre_san_1$Country == "NL"] <- "Netherlands"
pre_san_1$Country[pre_san_1$Country == "NO"] <- "Norway"
pre_san_1$Country[pre_san_1$Country == "SE"] <- "Sweden"
pre_san_1$Country[pre_san_1$Country == "GB"] <- "UK"
pre_san_1$Country[pre_san_1$Country == "LT"] <- "Lithuania"
pre_san_1$Country[pre_san_1$Country == "FR"] <- "France"

pre_san_2 <- summarise(group_by(pre_san_1, Year, Country, Source), ton = sum(ton))

pre_san_t <- spread(pre_san_2, key = Country, value = ton, fill = 0)
pre_san_t$Area <- "27.3.a + 27.4"

# Year-1 Last year ----
year <- substr(max(years), 3, 4)
last <- read.csv(paste0(path_out, "catch_year_area_from_sq_file_99_", year, ".csv"), sep = ";")
head(last)

last$Area <- NA
last$Area[last$area %in% c("27.3.a", "27.3.a.20", "27.3.31")] <- "27.3.a"
last$Area[last$area %in% c("27.4", "27.4.a", "27.4.b", "27.4.c")] <- "27.4"

last_1 <- subset(last, Area %in% c("27.3.a", "27.4"))

last_1$Source <- "HAWG members"
head(last_1)

last_2 <- subset(last_1, Year == max(years) & Area %in% c("27.3.a", "27.4"))
last_3 <- summarise(group_by(last_2, Year, Area, Country, Source), ton = sum(ton))

last_3$Year <- as.numeric(last_3$Year)

last_3$Country[last_3$Country == "DEN"] <- "Denmark"
last_3$Country[last_3$Country == "GER"] <- "Germany"
last_3$Country[last_3$Country == "NOR"] <- "Norway"
last_3$Country[last_3$Country == "SCO"] <- "UK"
last_3$Country[last_3$Country == "SWE"] <- "Sweden"

last_4 <- summarise(group_by(last_3, Year, Country, Source), ton = sum(ton))

last_4_t <- spread(last_4, key = Country, value = ton, fill = 0)
last_4_t$Area <- "27.3.a + 27.4"

# Combine ----
unique(old$Year)
old_sub <- subset(old, !(Year %in% years))
unique(pre_san_2$Year)

new <- bind_rows(old_sub, pre_san_t)

new_2 <- bind_rows(new, last_4_t)

new_2$Source[is.na(new_2$Source)] <- "To be filled"

new_2[is.na(new_2)] <- 0

new_2$Total[new_2$Total == 0] <- new_2$Denmark[new_2$Total == 0] +
  new_2$Germany[new_2$Total == 0] + new_2$Faroes[new_2$Total == 0] +
  new_2$Ireland[new_2$Total == 0] + new_2$Netherlands[new_2$Total == 0] +
  new_2$Norway[new_2$Total == 0] + new_2$Sweden[new_2$Total == 0] +
  new_2$UK[new_2$Total == 0] + new_2$Lithuania[new_2$Total == 0] +
  new_2$France[new_2$Total == 0]

write.csv(new_2, paste0(path_out, "/official_landings_52_", substr(max(years), 3, 4), ".csv"),
          row.names = F)
# 
# final_t <- gather(final, key = Country, -Year, -Source, -Species, -Area, value = ton)
# 
# final_t$Country[final_t$Country == "FR"] <- "France"
# 
# write.csv(final_t, paste0("Q:/mynd/Assessement_discard_and_the_like/assessment_scripts/HAWG_sandeel/2022/WKSANDEEL/input/official_landings_3a4abc_new_t.csv"),
#           row.names = F)
