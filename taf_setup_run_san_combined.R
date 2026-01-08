
library(icesTAF)


# taf.skeleton()
mkdir("boot/initial/data/submitted_data")

# Data ----
## Submitted data ----
### Expecting data from DE, NL, DK, SE, NO, UK-ENG, UK-SCO
### Yearly update needed

#### Germany
# No updated to 2023

draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_v2024_DE_2024.xlsx",
           data.scripts = NULL,
           originator = "Data submitted to HAWG",
           title = "2025 data from Germany. No updates to 2024",
           file = T,
           append = F)

#### The Nederlands
# No file. Personal communication - No landings in 2023 and 2024

#### Denmark
draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_DNK.csv",
           data.scripts = NULL,
           originator = "Data submitted to HAWG. Danish sample data are still on another server",
           title = "Landings data from Denmark",
           file = T,
           append = T)

#### Sweden
# No samples in 2024
draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_SWE_2023-2024.txt",
           data.scripts = NULL,
           originator = "Data submitted to HAWG",
           title = "Landings data from Sweden",
           file = T,
           append = T)

#### Norway
# No landings, samples and effort in 2025
# draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_Norway_Table1.csv",
#            data.scripts = NULL,
#            originator = "Data submitted to HAWG",
#            title = "Landings data from Norway",
#            file = T,
#            append = T)
# 
# draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_Norway_Table2.csv",
#            data.scripts = NULL,
#            originator = "Data submitted to HAWG",
#            title = "LD data from Norway",
#            file = T,
#            append = T)
# 
# draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_Norway_Table3.csv",
#            data.scripts = NULL,
#            originator = "Data submitted to HAWG",
#            title = "Single fish data from Norway",
#            file = T,
#            append = T)
# 
# draft.data(data.files = "submitted_data/catch_byVessel_byDay_2024.csv",
#            data.scripts = NULL,
#            originator = "Data submitted to HAWG",
#            title = "Effort data from Norway",
#            file = T,
#            append = T)

#### UK-ENG
draft.data(data.files = "submitted_data/Annex_1_HAWG_sandeel_exchange_format_UK_EW_v2024.xlsx",
           data.scripts = NULL,
           originator = "Data submitted to HAWG",
           title = "Effort data England and Wales",
           file = T,
           append = T)

#### UK-SCO
# No file. Personal communication - No landings in 2025

## ICES preliminary catch ----
### https://data.ices.dk/rec12/downloaddata
### Yearly update needed

draft.data(data.files = "preliminary_catch_statistics",
           data.scripts = NULL,
           originator = "ICES",
           title = "Preliminary catch statistic from ICES",
           file = T,
           append = T)

## Old data and references ----
### No yearly update should be needed
draft.data(data.files = "old_data",
           data.scripts = NULL,
           originator = "HAWG",
           title = "Old data needed for the run",
           file = T,
           append = T)

draft.data(data.files = "old_nor_data",
           data.scripts = NULL,
           originator = "Norway",
           title = "Old Norwegian sample data needed to update NOR sample data",
           file = T,
           append = T)

draft.data(data.files = "references",
           data.scripts = NULL,
           originator = "HAWG",
           title = "References need for the run",
           file = T,
           append = T)

## Output from last year ----
### Yearly update needed
draft.data(data.files = "outputs_from_last_year",
           data.scripts = NULL,
           originator = "HAWG",
           title = "Outputs from last years. This will be updated with the new run",
           file = T,
           append = T)

taf.boot()

# mkdir("data")
# mkdir("model/WKSAND16")


