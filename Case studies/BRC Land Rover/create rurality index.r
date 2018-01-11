##
## Create a 'rurality index'
## - from a combination of rural-urban classifications, journey times to key services, mental health issues (Scotland and Northern Ireland), and physical health issues (NI only)
## - the index is calculated at the these (equivalent) geographical levels: Lower Layer Super Output Area (LSOA; England, Wales), Data Zone (DZ; Scotland), and super Output Area (SOA; Northern Ireland)
## 
## NB: indices can only be used within each country, as each country's index is built using different underlying indicators
##
## This script does this:
## 1. Load National Statistics Postcode Lookup (NSPL)
## 2. Add Rural-Urban Classifications for Northern Ireland (not in NSPL by default)
## 3. Add Index of Multiple Deprivation (IMD) for Northern Ireland (not in NSPL by default)
## 4. Load Journey times to key services by Lower Layer Super Output Areas in England (other countries' IMD indictaors alreadu include these)
## 5. Load relevant IMD underlying indicators for each country's rurality index
## 6. Create rurality index via factor analysis of IMD indicators, journey times (England) and rural-urban classifications
## 7. Merge into NSPL and save to new .csv
##
## Before running this script, do the following:
## 1. Download the latest National Statistics Postcode Lookup file from: http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids
##    - put it in a 'Postcodes' sub-folder of `data.dir` (see below)
## 2. Download and process journey time data: run `ODS_Downloader.Rmd` in "IndexOfNeed/Datasets/Jouney Time Statistics 2015/Scripts/R"
## 3. Download and process indices of multiple deprivation: run `download all IMDs.r` in "IndexOfNeed/Datasets/IMD/Scripts/R"
## 4. Download and process rural-urban classifications: run `download rural urban classifications.r` in "IndexOfNeed/Datasets/Rural-Urban Classifications/Scripts/R"
##
library(tidyverse)
library(readxl)
library(httr)
library(caret)
library(polycor)

data.dir = "P:/Operations/Innovation & Insight/Insight/Data science/Data"  # change this as suits


###########################################################################################
## Postcodes
## source: http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids
## column descriptions are available Annex B of https://ago-item-storage.s3-external-1.amazonaws.com/1f6c4dfccc9545ccbb853afbe9833558/NSPL_User_Guide_Nov_2017.pdf?X-Amz-Security-Token=FQoDYXdzEBIaDDVhX9xIqSTA9aOsHyK3A81w9RQ%2Bjsec0aVKOnhu1Uq8MUtoT6xzZeFWUvk0urOKkcKik3BeLxwWc%2BCXP8z%2BGgZMXEeP%2BHHi74kGxLXAl59iUw4pPOJjIeMr%2B8Q%2BI0xQheMTC%2BizEaFZ2XfghVh9QEU812TQDvQzmUnlwsqTCsV3s6LyNHtx%2B4HJKXQQ5XEXl3ch%2B3WZS3WFKFcrST9axRAbTpuqNe3JKyaBju4gy%2F9y4cEv9%2F4gxU1tTTBRE3igj8d4f8Gv3lyn6CUS%2F2%2FgHma2fdXvFXok6SIskrdTaRH9C%2BncAb%2BIgdSn7P%2FD2FbdvT2%2FkX%2Bvc%2BBuohV0LBD64p6K0OYdo%2B9cNHEZ48yrL6hWRV8XDm89cxnqLWChJrAsSLV57cACfNpHUpUmfdxfRVVEvB%2Buo8BYSqlNjEzwHhZ3uHM4H5MkcKBStUzvIjiqsRAOIirXaRes6lfER%2BPwN6aHSbTydbhreH2alLw%2F36heqI20pwV%2BybNCu0GyS3pEsBc7uRSSf8Cabz1BzR5Hiz2nCIcF0uReWhbByj1nc5GD47t9iYSzDFekw94MV9W8EJMjpbaNSHYh5fvZ1UT1gqXHLyXGJbcouJbz0QU%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20171222T102253Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIAJ2EMZYLUTIJMK5PQ%2F20171222%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=7acfa17a5e027e60bf28c3208c24d88f261adb3ad8a14f20ae18a6d4d2705b2a
##
postcodes.raw = read_csv(file.path(data.dir, "Postcodes", "National_Statistics_Postcode_Lookup_Latest_Centroids.csv"),
                         col_types = cols(
                           X = col_double(),
                           Y = col_double(),
                           objectid = col_integer(),
                           dointr = col_integer(),
                           doterm = col_integer(),
                           usertype = col_integer(),
                           oseast1m = col_integer(),
                           osgrdind = col_integer(),
                           ru11ind = col_character(),
                           lat = col_double(),
                           long = col_double(),
                           imd = col_integer(),
                           .default = col_character()
                           ))


###########################################################################################
## Rural-urban classification for Northern Ireland
## (missing from `ru11ind` column in the National Stats Postcode Lookup)
## 
## Grab these from "Datasets/Rural-Urban Classifications"
## - if needed, run "Scripts/R/download rural urban classifications.r" in that folder first
##
# load directly from website
# GET("https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/Settlement15-lookup_0.xls",
#     write_disk(tf <- tempfile(fileext = ".xls")))
# ruc_ni = read_excel(tf, sheet="SA2011", skip=3)  # use the Small Areas classifications
# unlink(tf)  # remove the temp file

# load from Index of Need dataset
ruc_ni = read_csv("../../Datasets/Rural-Urban Classifications/Processed Data/RUC Northern Ireland - SA.csv") %>% 
  select(SA2011_Code, `Settlement Classification Band`, `2015 Default Urban/Rural`)

# merge into postcodes data
postcodes = postcodes.raw %>% 
  left_join(ruc_ni, by=c("oa11" = "SA2011_Code"))  # NI data uses output areas (called small areas in NI)

# copy the NI classifications into the `ru11ind` column (only where they're blank - which they all should be for NI)
postcodes$ru11ind = ifelse(is.na(postcodes$ru11ind), postcodes$`Settlement Classification Band`, postcodes$ru11ind)

# table(postcodes$`Settlement Classification Band`, postcodes$`2015 Default Urban/Rural`)

##
## add a binary rural/urban classification
##
postcodes = postcodes %>% 
  mutate(`Rural or Urban?` = case_when(
    ru11ind %in% c("A1", "B1", "C1", "C2",   # England and Wales
                   "1", "2", "3", "4", "5",  # Scotland
                   "A", "B", "C", "D", "E"   # Northern Ireland
    ) ~ "Urban",
    ru11ind %in% c("D1", "D2", "E1", "E2", "F1", "F2",  # England and Wales
                   "6", "7", "8",                       # Scotland
                   "F", "G", "H"                        # Northern Ireland
    ) ~ "Rural",
    TRUE ~ ""
))

# table(postcodes$`Rural or Urban?`) / nrow(postcodes)  # proportions of rural and urban Output/Small Areas


###########################################################################################
## Rural-urban classifications at lower layer super output area level (or equivalent)
## - to match up with journey times and indices of multiple deprivation
##
source("load rural-urban classifications.r")

# make sure the classifications are factors
ruc_eng_soa$RUC11 = factor(ruc_eng_soa$RUC11)
ruc_sco_soa$RUC11 = factor(ruc_sco_soa$RUC11)
ruc_ni_soa$RUC11  = factor(ruc_ni_soa$RUC11)


###########################################################################################
## Journey times to key services by lower layer super output area
## - source: https://www.gov.uk/government/statistical-data-sets/journey-times-to-key-services-by-lower-super-output-area-jts05
## - run `ODS_Downloader - LSOA.Rmd` in "IndexOfNeed/Datasets/Jouney Time Statistics 2015/Scripts/R" first to download and process the journey time data
##
journeys = read_csv("../../Datasets/Jouney Time Statistics 2015/Processed Data/Journey times to key services by LSOA.csv",
                    col_types = cols(
                      lsoa_code = col_character(),
                      region = col_character(),
                      la_code = col_character(),
                      la_name = col_character(),
                      .default = col_double()
                    ))

# keep only time to travel to GPs, hospitals, pharmacies, food stores and town centres
journeys = journeys %>% 
  select(lsoa_code, 
         
         # travel time in minutes to nearest...
         gpptt,         # GP by PT/walk
         # gpcart,        # GP by car  <-- this doesn't contain a lot of info; every LA is within 10 mins of a GP by car
         hospptt,       # hospital by PT/walk
         hospcart,      # hospital by car
         # phcart,        # pharmacy by car
         foodptt,       # food store by PT/walk
         # foodcart,      # food store by car <-- this doesn't contain a lot of info; almost every LA is within 11 mins of a food store by car (journeys %>% filter(foodcart < 120) %>% summarise(max(foodcart)))
         townptt        # town centre by PT/walk
         # towncart       # town centre by car
  )


###########################################################################################
## Add underlying indicators from the Indices of Multiple Deprivation for the four countries
## - merge in journey times to key services for england
## - merge in rural-urban classifications for all countries
##
source("load IMD underlying indicators.r")

# merge journey times into English IMD indicators
imd_eng = imd_eng %>% 
  left_join(journeys, by=c("lsoa11" = "lsoa_code"))

# merge rural/urban classification into each country's IMD subset
merge_ruc = function(df) df %>% left_join(postcodes %>% select(lsoa11, rural=`Rural or Urban?`) %>% distinct(), 
                                          by="lsoa11")

# england
imd_eng = imd_eng %>% 
  left_join(ruc_eng_soa)

# wales
imd_wal = imd_wal %>% 
  left_join(ruc_eng_soa) %>% 
  mutate(RUC11 = forcats::fct_drop(RUC11))  # refactor levels because not all in ruc_eng_soa are present in Wales

# scotland
imd_scot = imd_scot %>% 
  left_join(ruc_sco_soa)

# northern ireland
imd_ni = imd_ni %>% 
  left_join(ruc_ni_soa)


###########################################################################################
## Create rurality index
##
##
## PCA to create index for journey times
##
# # PCA using caret - Box-Cox transform the variables first
# trans = preProcess(journeys %>% select(-la_code) %>% as.matrix(),
#                    method=c("BoxCox", "center", "scale", "pca"))
# journeys.pca2 = predict(trans, journeys %>% select(-la_code) %>% as.matrix()) %>% 
#   as_data_frame()
# 
# # copy journey time index (principal component 1) into journeys data frame
# journeys$isol_idx = journeys.pca2$PC1

# make correlation matrices for factor analysis
# warning: takes a while to do this for England, since there are n > 32k
# but will only produce an 8x8 matrix, so no memory issues (hopefully)
imd_eng.cor = imd_eng %>% 
  select(-lsoa11) %>% 
  as.data.frame() %>% 
  hetcor() %>% 
  .$cor

imd_wal.cor = imd_wal %>% 
  select(-lsoa11) %>% 
  as.data.frame() %>% 
  hetcor() %>% 
  .$cor

imd_scot.cor = imd_scot %>% 
  select(-lsoa11) %>% 
  as.data.frame() %>% 
  hetcor() %>% 
  .$cor

imd_ni.cor = imd_ni %>% 
  select(-lsoa11) %>% 
  as.data.frame() %>% 
  hetcor() %>% 
  .$cor

##
## factor analysis
##
fa.eng  = factanal(covmat=imd_eng.cor,  factors=1, rotation="varimax")
fa.wal  = factanal(covmat=imd_wal.cor,  factors=1, rotation="varimax")
fa.scot = factanal(covmat=imd_scot.cor, factors=1, rotation="varimax")
fa.ni   = factanal(covmat=imd_ni.cor,   factors=1, rotation="varimax")

##
## make matrices for calculating scores
## - convert the categorical variable into a number first
##
convert_to_matrix = function(df) df %>% 
  select(-lsoa11) %>% 
  mutate(RUC11 = as.integer(RUC11)) %>% 
  as.matrix()

imd_eng.mat  = convert_to_matrix(imd_eng)
imd_wal.mat  = convert_to_matrix(imd_wal)
imd_scot.mat = convert_to_matrix(imd_scot)
imd_ni.mat   = convert_to_matrix(imd_ni)

##
## calculate factor scores
## source 1: https://stat.ethz.ch/pipermail/r-help/2002-April/020278.html
## source 2: https://stackoverflow.com/a/4146131
##
scores.eng  = as.matrix(imd_eng.mat)  %*% solve(fa.eng$correlation)  %*% loadings(fa.eng)
scores.wal  = as.matrix(imd_wal.mat)  %*% solve(fa.wal$correlation)  %*% loadings(fa.wal)
scores.scot = as.matrix(imd_scot.mat) %*% solve(fa.scot$correlation) %*% loadings(fa.scot)
scores.ni   = as.matrix(imd_ni.mat)   %*% solve(fa.ni$correlation)   %*% loadings(fa.ni)

##
## scores for each LSOA
##
imd_eng$rurality  = scores.eng[,1]
imd_wal$rurality  = scores.wal[,1]
imd_scot$rurality = scores.scot[,1]
imd_ni$rurality   = scores.ni[,1]

# bind into a single dataframe before merging
imd_uk = bind_rows(
  imd_eng  %>% select(lsoa11, rurality),
  imd_wal  %>% select(lsoa11, rurality),
  imd_scot %>% select(lsoa11, rurality),
  imd_ni   %>% select(lsoa11, rurality)
)

##
## merge rurality index by LSOA
##
postcodes = postcodes %>% 
  left_join(imd_uk, by="lsoa11")

# look at assoc. between rurality index and rural/urban classification
postcodes %>% 
  select(ctry, `Rural or Urban?`, rurality) %>% 
  filter(substr(ctry, 1, 1) %in% c("E", "S", "W", "N")) %>% 
  na.omit() %>% 
  ggplot(aes(x=`Rural or Urban?`, y=rurality)) + 
  geom_boxplot() + 
  facet_wrap(~ctry, scales = "free_y")


###########################################################################################
## keep only postcodes, coordinates and some other local info
##
postcodes.sub = postcodes %>% 
  select(Postcode = pcd, Longitude = long, Latitude = lat
         , Country = ctry
         ,`Output Area` = oa11  # 'Output Area' in England, Scotland and Wales; 'Small Area' in NI 
         , LSOA = lsoa11        # Lower Layer Super Output Area (Eng, Wal); Super Output Area (NI); Data Zone (Sco)
         ,`Local Authority Code` = laua
         ,`Rural or Urban?`
         ,`Rural Urban classification` = ru11ind
         , IMD = imd
         ,`Rurality index` = rurality
  )

# save
write_csv(postcodes.sub, file.path(data.dir, "Postcodes", "National_Statistics_Postcode_Lookup - BRC.csv"))
