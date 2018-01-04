##
## Rural-Urban classification (RUC2011)
##
## England's local authority districts are categorised from 1-6
## Scotland has several classifications but for compatibility, we'll use their 1-6 scale (UR6FOLD)
## Northern Ireland 
##
library(tidyverse)
library(readxl)

# BRC volunteers
vols = read_csv("../../../../Data/Volunteers/volunteers - 18-12-17.csv")

# National Statistics postcode lookup
# source: 
postcodes = read_csv("../../../../Data/National_Statistics_Postcode_Lookup_UK.csv")


####################################################################################
## Rural-urban classifications
##
## Local authority districts in England
## source: https://ons.maps.arcgis.com/home/item.html?id=0560301db0de440aa03a53487879c3f5
##
ruc2011_eng = read_csv("Data/England/RUC_LAD_2011_EN_LU.csv")


# 
# lads = postcodes %>% 
#   select(`Local Authority Code`, `Local Authority Name`) %>% 
#   distinct()
# 
# lads %>% 
#   filter(`Local Authority Code` == "N00000001")

##
## Scotland
## source: http://www.gov.scot/Publications/2014/11/2763/downloads
##
# ruc2011_scot = read_excel("Data/Scotland/SGUR Population Tables 2014 - NRS.xlsx", skip=2,
#                           sheet="CA6FOLD")  # Council Areas, 6-fold classification

ruc2011_scot = read_csv("Data/Scotland/PC2014r2_SGUR2013_2014_Lookup_Public.txt")  # rural-urban classifications for postcodes

# postcodes in our volunteer data don't have spaces; remove spaces here too
ruc2011_scot$POSTCODE = gsub(" ", "", ruc2011_scot$POSTCODE)

# table(ruc2011_scot$UR8FOLD, ruc2011_scot$UR2FOLD)

##
## Northern Ireland
##
# load directly from website
GET("https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/Settlement15-lookup_0.xls",
    write_disk(tf <- tempfile(fileext = ".xls")))

ruc_ni = read_excel(tf, sheet="SA2011", skip=3)  # use the Small Areas classifications

unlink(tf)  # remove the temp file
