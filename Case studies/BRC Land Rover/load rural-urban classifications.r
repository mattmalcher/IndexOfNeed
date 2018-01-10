##
## Load rural-urban classifications at equivalent geography levels
## - lower layer super output area (England, Wales)
## - super output area (NI)
## - data zone (Scotland)
##
## If needed, run the .r scripts in IndexOfNeed\Datasets\Rural-Urban Classifications\Scripts\R\ to download and pre-process the data
##
library(tidyverse)

dir.data.ruc = "../../Datasets/Rural-Urban Classifications/Processed Data"

# England and Wales
ruc_eng_soa = read_csv(file.path(dir.data.ruc, "RUC England Wales - LSOA.csv")) %>% 
  select(lsoa11 = LSOA11CD,  # use the same column name as the National Stats Postcode Lookup
         RUC11 = RUC11CD
         )

# Scotland
ruc_sco_soa = read_csv(file.path(dir.data.ruc, "RUC Scotland - DZ.csv")) %>% 
  select(lsoa11 = DZ_CODE,  # use the same column name as the National Stats Postcode Lookup
         RUC11 = UR8FOLD    # use the 8-fold classification (to match number of England/Wales categories)
         )

# NI
ruc_ni_soa = read_csv(file.path(dir.data.ruc, "RUC Northern Ireland - SOA.csv")) %>% 
  select(lsoa11 = `SOA Code`,  # use the same column name as the National Stats Postcode Lookup
         RUC11 = `2015 Default Urban/Rural`
         )
