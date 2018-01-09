##
## Download and process Welsh IMD data: 
## - Indicator data by Lower Layer Super Output Areas - All Domains
##
library(jsonlite)
library(RCurl)
library(dplyr)
library(readr)
library(tidyr)

source("../../../../init.r")

# load initial data
wimd_curr = fromJSON(getURL("http://open.statswales.gov.wales/en-gb/dataset/wimd0004"), flatten=T)

# put data into data.frame
wimd_dat = wimd_curr$value

# get url of the first next page
next_page = wimd_curr$odata.nextLink

# loop over the .json pages until we run out of data
while(!is.null(next_page)) {
  wimd_curr = fromJSON(getURL(next_page), flatten=T)  # download next batch of data
  
  wimd_dat = bind_rows(wimd_dat, wimd_curr$value)  # append to data.frame
  next_page = wimd_curr$odata.nextLink             # get url of next page (if there is one)
  
  print(next_page)  # track progress
}

# save the long-format version of the data
# re-order the columns so that `Data` isn't first (which causes 'bad restore file magic number' errors); also rename it
wimd_dat %>% 
  select(-Data, Value=Data) %>%  # source: https://stackoverflow.com/a/43902237
  write_csv(file.path(dir_data_out, "WIMD - all indicators - long format.csv"))

# save indicator metadata
metadata = wimd_dat %>% 
  select(Indicator_Code, Indicator_ItemName_ENG, Indicator_ItemNotes_ENG, Indicator_Hierarchy, Indicator_SortOrder) %>% 
  distinct() %>% 
  write_csv(file.path(dir_data_out, "WIMD - all indicators - metadata.csv"))

# save wide-format version of the data
wimd_wide = wimd_dat %>% 
  select(Year_Code, Area_Code:Area_AltCode1, Indicator_Code, Data) %>% 
  distinct() %>% 
  filter(Data > -1000) %>%  # get rid of missing data (coded as -1e09); it will appear as NA in the wide-format data.frame
  spread(Indicator_Code, Data)

write_csv(wimd_wide, file.path(dir_data_out, "WIMD - all indicators - wide format.csv"))
