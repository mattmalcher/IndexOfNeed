##
## Download and process English IMD data
##
library(tidyverse)
library(readxl)

source("init.r")

imd_url = "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/467775/File_8_ID_2015_Underlying_indicators.xlsx"
imd_path = file.path(dir.data.in, "English_IMD.xlsx")

download.file(imd_url, imd_path, mode="wb")

# get list of worksheets, separating the metadata sheet from data sheets
imd_sheets = excel_sheets(imd_path)
metadata_sheet = imd_sheets[1]
imd_sheets = imd_sheets[-1]

##
## save each of the domains into separate .csv files
##
# for (sheet in imd_sheets) {
#   fname = paste0("EIMD - ", sheet, ".csv")
#   
#   read_excel(imd_path, sheet=sheet) %>% 
#     write_csv(file.path(dir.data.out, fname))
#   
#   print(paste0("Saved ", fname))
# }

##
## save all domains in a single .csv file
##
# read all worksheets into a single list
imds = list()
for (i in 1:length(imd_sheets)) {
  imds[[i]] = read_excel(imd_path, sheet=imd_sheets[i])
}

# merge list into a single dataframe
imds_merged = Reduce(function(d1, d2) left_join(d1, d2, 
                                                by=c("LSOA code (2011)", "LSOA name (2011)", "Local Authority District code (2013)", "Local Authority District name (2013)")), 
                     imds)

write_csv(imds_merged, file.path(dir.data.out, "EIMD - all indicators.csv"))

##
## process metadata in 'Notes' worksheet
##
imd_metadata = read_excel(imd_path, sheet=metadata_sheet, range = "B8:G38")  # keep only the table

# the Indicator column contains multiple entries separated by CR-LFs; expand them into separate rows
imd_metadata = imd_metadata %>% 
  unnest(Indicator = strsplit(Indicator, "\\r\\n")) %>%
  select(Domain, Indicator, everything()) %>%   # put columns back in correct order
  fill(Domain)  # # fill Domain column downwards to fill in NAs

write_csv(imd_metadata, file.path(dir.data.out, "EIMD - all indicators - metadata.csv"))
