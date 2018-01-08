##
## Use underlying indicators relating to mental health and access to services from the IMDs
## - different indicators for each country
## - combine them into within-country rurality indices (actually to combination in `load postcodes...r`)
##
## If needed, run the .r scripts in IndexOfNeed\Datasets\IMD\Scripts\R\ to download and pre-process the data
##
library(tidyverse)

dir.data.imd = "../../Datasets/IMD/Processed Data"


#############################################################################################
## England
## - road distance to food stores (average, in km)
## - road distance to GP (average, in km)
## - mood and anxiety disorders (mood, neurotic, stress-related and somatoform disorders; higher score = higher deprivation)
##
imd_eng = read_csv(file.path(dir.data.imd, "EIMD - all indicators.csv")) %>% 
  select(lsoa11 = `LSOA code (2011)`,  # use the same column name as the National Stats Postcode Lookup
         ENG_1 = `Mood and anxiety disorders indicator`)

# may as well use the 'Journey time to key services' stats instead of these - the former are more comprehensive
# imd_eng$`Road distance to a GP surgery indicator (km)`
# imd_eng$`Road distance to general store or supermarket indicator (km)`


#############################################################################################
## Wales
## - average public travel time to food shop (minutes)
## - average public travel time to GP surgery (minutes)
## - average public travel time to pharmacy (minutes)
## - average private travel time to food shop (minutes)
## - average private travel time to GP surgery (minutes)
## - average private travel time to pharmacy (minutes)
##
imd_wal = read_csv(file.path(dir.data.imd, "WIMD - all indicators - wide format.csv")) %>% 
  select(lsoa11 = Area_Code,  # use the same column name as the National Stats Postcode Lookup
         WAL_1 = PRFS,  # average private travel time to food shop (minutes)
         WAL_2 = PRGP,  # average private travel time to GP surgery (minutes)
         WAL_3 = PRPH,  # average private travel time to pharmacy (minutes)
         WAL_4 = PUFS,  # average public travel time to food shop (minutes)
         WAL_5 = PUGP,  # average public travel time to GP surgery (minutes)
         WAL_6 = PUPH   # average public travel time to pharmacy (minutes)
  )


#############################################################################################
## Scotland
##
## - avg drive time to GP survey (minutes)
## - avg drive time to retail centre (mins)
## - public transport travel time to GP (mins)
## - public transport travel time to retail centre (mins)
## - proportion of population prescribed drugs for anxiety, depression or psychosis
##
imd_scot = read_csv(file.path(dir.data.imd, "SIMD - all indicators.csv")) %>% 
  select(lsoa11 = Data_Zone,  # use the same column name as the National Stats Postcode Lookup
         SCO_1 = PT_GP,
         SCO_2 = PT_retail,
         SCO_3 = drive_GP, 
         SCO_4 = drive_retail,
         SCO_5 = DEPRESS  # proportion of population prescribed drugs for anxiety, depression or psychosis
  )


#############################################################################################
## NI
## - Combined Mental Health Indicator (rank; lower is more deprived)
## - Standardised proportion of people with a long term health problem or disability (excluding mental health)
## - Service-weighted fastest travel time by private transport (rank)
## - Service-weighted fastest travel time by public transport (rank)
##
imd_ni = read_csv(file.path(dir.data.imd, "NIMDM - all indicators.csv")) %>% 
  select(lsoa11 = SOA2001,  # use the same column name as the National Stats Postcode Lookup
         NI_1 = `Combined Mental Health Indicator (rank)`,
         NI_2 = `Standardized ratio of people with a long-term health problem or disability (Excluding Mental Health problems) (rank)`,
         NI_3 = `Service-weighted fastest travel time by private transport (rank)`,
         NI_4 = `Service-weighted fastest travel time by public transport (rank)`
  )
