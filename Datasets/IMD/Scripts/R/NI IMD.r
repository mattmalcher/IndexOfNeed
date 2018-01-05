##
## Download and process Northern Ireland Multiple Deprivation Measure data
##
library(tidyverse)
library(readxl)
library(xlsx)

source("init.r")

imd_url = "https://www.nisra.gov.uk/sites/nisra.gov.uk/files/publications/NIMDM17_SOAresults.xls"
imd_path = file.path(dir.data.in, "NI_IMD.xls")

download.file(imd_url, imd_path, mode="wb")

# get list of worksheets, separating the metadata sheet from data sheets
imd_sheets = excel_sheets(imd_path)
metadata_sheet = imd_sheets[1]
imd_sheets = imd_sheets[-1]

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
                                                by=c("LGD2014NAME", "2015 Default Urban/Rural",	"SOA2001", "SOA2001_name")), 
                     imds)

write_csv(imds_merged, file.path(dir.data.out, "NIMDM - all indicators.csv"))

##
## process metadata
## - it's not formatted as a tidy table, so just make a copy of the origind workbook but keep only the metadata tab
##
wb = loadWorkbook(imd_path)

for (sheet in imd_sheets) removeSheet(wb, sheetName = sheet)

saveWorkbook(wb, file.path(dir.data.out, "NIMDM - all indicators - metadata.xls"))
