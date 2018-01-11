# British Red Cross case study: Land Rover Support at Home services
Land Rover funds 11 projects in locations around the UK to provide support to people suffering from social isolation, particularly in rural areas.

The aim of this case study is to develop an indicator for the availability (or lack) of transport to key services, as well as mapping the rural-ness of existing service users.

The code in this folder uses [data about journey times]() to create a single numerical index representing distance from key services. It also combines this index with [rural-urban classification data]() and produces a binary measure of whether a postcode is rural or urban.

## Creating the rurality index
Creates a single measure of an areas rurality from a combination of:
- [rural-urban classifications](https://github.com/mattmalcher/IndexOfNeed/wiki/Data-Source-%E2%80%90-Rural-Urban-Classification)
- [journey times to key services](https://github.com/mattmalcher/IndexOfNeed/wiki/Data-Source-%E2%80%90-Journey-Times-to-Key-Services)
- mental health issues (Scotland and Northern Ireland; from [Index of Multiple Deprivation](https://github.com/mattmalcher/IndexOfNeed/tree/master/Datasets/IMD))
- physical health issues (NI only; from [Index of Multiple Deprivation](https://github.com/mattmalcher/IndexOfNeed/tree/master/Datasets/IMD))

The index is calculated at the these (equivalent) geographical levels: Lower Layer Super Output Area (LSOA; England, Wales), Data Zone (DZ; Scotland), and super Output Area (SOA; Northern Ireland)

Rurality indices can only be used within each country, as each country's index is built using different underlying indicators

The steps to create the index are:
1. Load National Statistics Postcode Lookup (NSPL)
2. Add Rural-Urban Classifications for Northern Ireland (not in NSPL by default)
3. Add Index of Multiple Deprivation (IMD) for Northern Ireland (not in NSPL by default)
4. Load Journey times to key services by Lower Layer Super Output Areas in England (other countries' IMD indictaors alreadu include these)
5. Load relevant IMD underlying indicators for each country's rurality index
6. Create rurality index via factor analysis of IMD indicators, journey times (England) and rural-urban classifications
7. Merge into NSPL and save to new .csv

This case study has the following prerequisites:
1. Download the latest [National Statistics Postcode Lookup](http://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-latest-centroids) file
2. Download and process journey time data: run `ODS_Downloader.Rmd` in "IndexOfNeed/Datasets/Jouney Time Statistics 2015/Scripts/R"
3. Download and process indices of multiple deprivation: run `download all IMDs.r` in "IndexOfNeed/Datasets/IMD/Scripts/R"
4. Download and process rural-urban classifications: run `download rural urban classifications.r` in "IndexOfNeed/Datasets/Rural-Urban Classifications/Scripts/R"
