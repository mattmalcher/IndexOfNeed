##
## Rural-Urban classifications for the UK countries
##
## This script downloads and outputs data at the following geographical levels
## - lower super output area (England and Wales) / data zone (Scotland) / super output area (NI) <-- these are equivalent geographical levels
## - output area (England, Wales and Scotland) / small area (NI)
## - local authority district (England only)
##
## Note that postcode-level classifications are available in the National Statistics Postcode Lookup
## (http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids)
##
library(tidyverse)
library(readxl)

source("../../../../init.r")

##
## URLs for each country's classification files
## - "lsoa" refers to lower layer super output area
## - "lad" refers to local authority district
##
url_oa_eng   = "https://ons.maps.arcgis.com/sharing/rest/content/items/3ce248e9651f4dc094f84a4c5de18655/data"
url_lsoa_eng = "https://ons.maps.arcgis.com/sharing/rest/content/items/9855221596994bde8363a685cb3dd58a/data"
url_lad_eng  = "https://ons.maps.arcgis.com/sharing/rest/content/items/0560301db0de440aa03a53487879c3f5/data"

url_sco = "http://www.gov.scot/Resource/0046/00464793.zip"

url_ni = "https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/Settlement15-lookup_0.xls"

##
## filenames
##
# don't use file extensions because we need some flexibility - some are .csv, .zip, .xls, .txt etc.
file_oa_eng   = "RUC England Wales - OA"    # output areas
file_lsoa_eng = "RUC England Wales - LSOA"  # lower layer super output areas
file_lad_eng  = "RUC England - LAD"         # local authority districts

file_sco    = "RUC Scotland"       # the main .zip file
file_oa_sco = "RUC Scotland - OA"  # output areas
file_dz_sco = "RUC Scotland - DZ"  # data zones

file_ni     = "RUC Northern Ireland"        # this will be the main Excel file downloaded
file_sa_ni  = "RUC Northern Ireland - SA"   # small areas
file_soa_ni = "RUC Northern Ireland - SOA"  # super output areas


####################################################################################
## England and Wales
##

##
## classification by output area (OA)
## - this is a .zip file, so download then unzip
##
download.file(url_oa_eng, file.path(dir_data_in, paste0(file_oa_eng, ".zip")), mode="wb")
unzip(file.path(dir_data_in, paste0(file_oa_eng, ".zip")), exdir=dir_data_in)

# copy the .csv file to output folder
file.copy(file.path(dir_data_in, "RUC11_OA11_EW.csv"), file.path(dir_data_out, paste0(file_oa_eng, ".csv")))

##
## classification by lower layer super output area (LSOA)
##
download.file(url_lsoa_eng, file.path(dir_data_in, paste0(file_lsoa_eng, ".csv")), mode="wb")

# make a copy in the output folder
file.copy(file.path(dir_data_in, paste0(file_lsoa_eng, ".csv")), file.path(dir_data_out, paste0(file_lsoa_eng, ".csv")))

##
## classification by local authority districts
## - this is a .zip file, so download then unzip
##
download.file(url_lad_eng, file.path(dir_data_in, paste0(file_lad_eng, ".zip")), mode="wb")
unzip(file.path(dir_data_in, paste0(file_lad_eng, ".zip")), exdir=dir_data_in)

# copy the .csv file to output folder
file.copy(file.path(dir_data_in, "RUC_LAD_2011_EN_LU.csv"), file.path(dir_data_out, paste0(file_lad_eng, ".csv")))


####################################################################################
## Scotland
##
download.file(url_sco, file.path(dir_data_in, paste0(file_sco, ".zip")), mode="wb")
unzip(file.path(dir_data_in, paste0(file_sco, ".zip")), exdir=dir_data_in)

# copy the .csv files to output folder
#... output areas
file.copy(file.path(dir_data_in, "OA2011_SGUR2013_2014_Lookup.txt"), 
          file.path(dir_data_out, paste0(file_oa_sco, ".csv")))

#... data zones
file.copy(file.path(dir_data_in, "DZ2011_SGUR2013_2014_Lookup.txt"), 
          file.path(dir_data_out, paste0(file_dz_sco, ".csv")))


####################################################################################
## Northern Ireland
##
download.file(url_ni, file.path(dir_data_in, paste0(file_ni, ".xls")), mode="wb")

# save Small Area classifications
read_excel(file.path(dir_data_in, paste0(file_ni, ".xls")), 
           sheet="SA2011", skip=3) %>%
  mutate(X__1 = NULL) %>%   # remove empty and pointless column
  write_csv(file.path(dir_data_out, paste0(file_sa_ni, ".csv")))

# save Super Output Area classifications
read_excel(file.path(dir_data_in, paste0(file_ni, ".xls")), 
           sheet="SOA2011", skip=3) %>%
  write_csv(file.path(dir_data_out, paste0(file_soa_ni, ".csv")))
