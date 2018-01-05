# Indices of Multiple Deprivation (IMD)
The Index of Multiple Deprivation for each country in the UK is comprised of a series of underlying indicators of deprivation in the following domains:

- Income (All)
- Employment (All)
- Health and disability (All)
- Education, skills and training (All)
- Crime (England, NI, Scotland)
- Community safety (Wales)
- Access to services (All; in England, includes housing)
- Living environment (England, NI)
- Housing (Scotland, Wales)
- Physical environment (Wales)

(The exact domains and the contents of each vary by country.)

We're interested in using subsets of these underlying indicators in creating an Index of Need. For example, the [British Red Cross case study](https://github.com/mattmalcher/IndexOfNeed/tree/master/Case%20studies/BRC%20Land%20Rover) could use indicators in the 'access to services' domain as part of its 'rurality index'.

The indicators are presented at equivalent [Statistical Building Blocks](https://www.ons.gov.uk/methodology/geography/ukgeographies/censusgeography#super-output-area-soa) across the four countries:

- England: Super Output Areas, Lower Layer
- Scotland: Data Zones
- Wales: Super Output Areas, Lower Layer
- Northern Ireland: Super Output Areas

## England
The data are available from [GOV.UK](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2015); we want [File 8: underlying indicators](https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/467775/File_8_ID_2015_Underlying_indicators.xlsx).

The R script downloads the data in Excel format and outputs all the domain indicators into a single .csv file. It also outputs the table of indicators in the `Notes` worksheet as a metadata file.

## Wales
The [Welsh Government](www.gov.wales/wimd) is in charge of the Welsh IMD (WIMD); data are available from [StatsWales](https://statswales.gov.wales/Catalogue/Community-Safety-and-Social-Inclusion/Welsh-Index-of-Multiple-Deprivation/WIMD-Indicator-Analysis).

These data are in .json format and are paginated - the R script downloads the entire dataset directly from StatsWales and saves the following files:

- full dataset (long format)
- full dataset (wide format)
- metadata

## Scotland
The data are available from the [Scottish Government](http://www.gov.scot/Topics/Statistics/SIMD); we want the [SIMD16 indicator data](http://www.gov.scot/Resource/0051/00510566.xlsx).

The R script downloads the data in Excel format and outputs all the domain indicators into a single .csv file. It also outputs the table of indicators in the `Indicator descriptions` worksheet as a metadata file.

## Northern Ireland
This is known as the Northern Ireland Multiple Deprivation Measure (NIMDM). Data are available from the [Northern Ireland Statistics and Research Agency](https://www.nisra.gov.uk/statistics/deprivation/northern-ireland-multiple-deprivation-measure-2017-nimdm2017#toc-0); we're using the [SOA [Super Output Area] level results](https://www.nisra.gov.uk/publications/nimdm17-soa-level-results).

The R script downloads the data in Excel format and outputs all the domain indicators into a single .csv file. It also outputs the contents of the `Metadata` worksheet as a metadata file (in Excel format).
