##
## Create a 'rurality index/indices'
## - combine postcode-level rural-urban classifications for England, Wales and Scotland with small area (i.e. output area) classifications for Northern Ireland
## - create an index for 'journey times to key services' for local authorities in England
##
## To do/consider:
## - include rural-urban classification in the factor analysis/PCA to derive a single index?
## --- rather than choosing the dimensionality reduction method based on how well it predicts rurality
##
## Before running this script, do the following:
## 1. Download the latest National Statistics Postcode Lookup file from: http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids
##    - put it in a 'Postcodes' sub-folder of `data.dir` (see below)
## 2. Download and process journey time data by running `ODS_Downloader.Rmd` in "IndexOfNeed/Datasets/Jouney Time Statistics 2015/Scripts/R"
##
library(tidyverse)
library(readxl)
library(httr)
library(caret)

data.dir = "P:/Operations/Innovation & Insight/Insight/Data science/Data"  # change this as suits


###########################################################################################
## Postcodes
## source: http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids
## column descriptions are available Annex B of https://ago-item-storage.s3-external-1.amazonaws.com/1f6c4dfccc9545ccbb853afbe9833558/NSPL_User_Guide_Nov_2017.pdf?X-Amz-Security-Token=FQoDYXdzEBIaDDVhX9xIqSTA9aOsHyK3A81w9RQ%2Bjsec0aVKOnhu1Uq8MUtoT6xzZeFWUvk0urOKkcKik3BeLxwWc%2BCXP8z%2BGgZMXEeP%2BHHi74kGxLXAl59iUw4pPOJjIeMr%2B8Q%2BI0xQheMTC%2BizEaFZ2XfghVh9QEU812TQDvQzmUnlwsqTCsV3s6LyNHtx%2B4HJKXQQ5XEXl3ch%2B3WZS3WFKFcrST9axRAbTpuqNe3JKyaBju4gy%2F9y4cEv9%2F4gxU1tTTBRE3igj8d4f8Gv3lyn6CUS%2F2%2FgHma2fdXvFXok6SIskrdTaRH9C%2BncAb%2BIgdSn7P%2FD2FbdvT2%2FkX%2Bvc%2BBuohV0LBD64p6K0OYdo%2B9cNHEZ48yrL6hWRV8XDm89cxnqLWChJrAsSLV57cACfNpHUpUmfdxfRVVEvB%2Buo8BYSqlNjEzwHhZ3uHM4H5MkcKBStUzvIjiqsRAOIirXaRes6lfER%2BPwN6aHSbTydbhreH2alLw%2F36heqI20pwV%2BybNCu0GyS3pEsBc7uRSSf8Cabz1BzR5Hiz2nCIcF0uReWhbByj1nc5GD47t9iYSzDFekw94MV9W8EJMjpbaNSHYh5fvZ1UT1gqXHLyXGJbcouJbz0QU%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20171222T102253Z&X-Amz-SignedHeaders=host&X-Amz-Expires=300&X-Amz-Credential=ASIAJ2EMZYLUTIJMK5PQ%2F20171222%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=7acfa17a5e027e60bf28c3208c24d88f261adb3ad8a14f20ae18a6d4d2705b2a
##
postcodes = read_csv(file.path(data.dir, "Postcodes", "National_Statistics_Postcode_Lookup_Latest_Centroids.csv"),
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
# load directly from website
GET("https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/Settlement15-lookup_0.xls",
    write_disk(tf <- tempfile(fileext = ".xls")))
ruc_ni = read_excel(tf, sheet="SA2011", skip=3)  # use the Small Areas classifications
unlink(tf)  # remove the temp file

ruc_ni = ruc_ni %>% 
  select(SA2011_Code, `Settlement Classification Band`, `2015 Default Urban/Rural`)

# merge into postcodes data
postcodes = postcodes %>% 
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
## Journey times to key services by local authority
## - source: https://www.gov.uk/government/statistical-data-sets/journey-times-to-key-services-by-local-authority-jts04
## - run `ODS_Downloader.Rmd` in "IndexOfNeed/Datasets/Jouney Time Statistics 2015/Scripts/R" first to download and process the journey time data
##
journeys = read_csv("../../Datasets/Jouney Time Statistics 2015/Processed Data/Journey times to key services by local authority.csv")

# keep only time to travel to GPs, hospitals, pharmacies, food stores and town centres
journeys = journeys %>% 
  select(la_code, 
         
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

##
## PCA to create index for journey times
##
# PCA using caret - Box-Cox transform the variables first
trans = preProcess(journeys %>% select(-la_code) %>% as.matrix(),
                   method=c("BoxCox", "center", "scale", "pca"))
journeys.pca2 = predict(trans, journeys %>% select(-la_code) %>% as.matrix()) %>% 
  as_data_frame()

# copy journey time index (principal component 1) into journeys data frame
journeys$isol_idx = journeys.pca2$PC1

##
## merge travel time index by local authority codes
##
postcodes = postcodes %>% 
  left_join(journeys, by=c("laua" = "la_code"))


###########################################################################################
## Add underlying indicators from the Indices of Multiple Deprivation for the four countries
##



###########################################################################################
## keep only postcodes, coordinates and some other local info
##
postcodes = postcodes %>% 
  select(Postcode = pcd, Longitude = long, Latitude = lat
         , Country = ctry
         ,`Local Authority Code` = laua
         ,`Output Area` = oa11  # 'Output Area' in England, Scotland and Wales; 'Small Area' in NI 
         , LSOA = lsoa11  # Lower Layer Super Output Area (Eng, Wal); Super Output Area (NI); Data Zone (Sco)
         ,`Rural or Urban?`
         ,`Rural Urban classification` = ru11ind
         , IMD = imd
         ,`Journey time index` = isol_idx
  )

# save
write_csv(postcodes, file.path(data.dir, "Postcodes", "National_Statistics_Postcode_Lookup - BRC.csv"))
