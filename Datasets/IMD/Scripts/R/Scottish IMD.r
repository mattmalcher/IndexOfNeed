##
## Download and process Scottish IMD data
##
library(tidyverse)
library(readxl)

source("../../../../init.r")

imd_url = "http://www.gov.scot/Resource/0051/00510566.xlsx"
imd_path = file.path(dir_data_in, "Scottish_IMD.xlsx")

download.file(imd_url, imd_path, mode="wb")

##
## process domain indicators
##
imd = read_excel(imd_path, sheet="Data", na="*")

# force Total Population to be integer to stop 1000 being saved at 1.00E3 and subsequently causing errors when reading data back in to R
imd$Total_population = as.integer(imd$Total_population)

write_csv(imd, file.path(dir_data_out, "SIMD - all indicators.csv"))

##
## process metadata
##
imd_metadata = read_excel(imd_path, sheet="Indicator descriptions") %>% 
  {names(.)[1] = "Domain"; .} %>%   # source: https://stackoverflow.com/a/47907058
  fill(Domain)

write_csv(imd_metadata, file.path(dir_data_out, "SIMD - all indicators - metadata.csv"))
