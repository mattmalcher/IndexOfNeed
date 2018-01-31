# Script for getting Stat-Xplore data using the stat_xplore scraper libraries to access the Stat-Xplore API
import sys
sys.path.append('.\stat_xplore_scraper')
import stat_xplore_table
import stat_xplore_schema
import pandas as pd



#######################
#
#
# Set fixed variables
#
# URLs are the URLs of the API endpoints
# APIKey is the code used to authorise the API request
# 'headers' dictionaries contain the header infomation for API requests
#
#
#######################

APIKey = '65794a30655841694f694a4b563151694c434a68624763694f694a49557a49314e694a392e65794a7063334d694f694a7a644849756333526c6247786863694973496e4e3159694936496d39696153357a59584a6e623235705147396a63326b7559323875645773694c434a70595851694f6a45314d5463304d544d7a4d7a4573496d46315a434936496e4e30636935765a47456966512e4f495a704539425437446d32416649546a6c696e474e643437464c46305655656c34433535646c6f537530'
table_headers = {'APIKey':APIKey,
                'Content-Type':'applciation/json'}
schema_headers = {'APIKey':APIKey}

output_directory = '..\..\Data\\'

# Get the Stat-Xplore schema. This is used to find the codes of fields and values when getting data
# This takes a while. Need to fix encoding issue so user can read in saved schema instead of querying API for new one
df_schema = stat_xplore_schema.get_full_schema(schema_headers, check_cache = True, schema_filename = '.\stat_xplore_scraper\schema.csv')

#######################
#
#
# Function calls to get data
#
# stat_xplore_table.get_stat_xplore_measure_data() returns a dictionary with two items
#   'data' - a pandas DataFrame of the requested data; 'annotations' - notes about the data
#
#######################


# Numbers of people claiming Carers Allowance by local authority, quarter and gender
ca = stat_xplore_table.get_stat_xplore_measure_data(table_headers, 
                                                    schema_headers, 
                                                    measure_id = 'str:count:CA_In_Payment:V_F_CA_In_Payment', 
                                                    field_ids = ['str:field:CA_In_Payment:F_CA_QTR:DATE_NAME',
                                                                 'str:field:CA_In_Payment:V_F_CA_In_Payment:CCSEX'], 
                                                    fields_include_total = 'str:field:CA_In_Payment:V_F_CA_In_Payment:CCSEX',
                                                    df_schema = df_schema, 
                                                    geog_folder_label = 'Geography (residence-based)', 
                                                    geog_field_label= 'National - Regional - LA - OAs', 
                                                    geog_level_label = 'Local Authority')
# Save the data and annotations
ca['data'].to_csv(output_directory + 'carers_allowance_data.csv', index=False)
with open(output_directory + 'carers_allowance_annotations.txt', 'w') as f:
    for annotation in ca['annotations'].values():
        f.write(annotation+'\n\n')


# Numbers claiming Personal Inepedence Payments by local authority, month and disability type
pip = stat_xplore_table.get_stat_xplore_measure_data(table_headers, 
                                                    schema_headers, 
                                                    measure_id = 'str:count:PIP_Monthly:V_F_PIP_MONTHLY', 
                                                    field_ids = ['str:field:PIP_Monthly:V_F_PIP_MONTHLY:DISABILITY_CODE',
                                                                 'str:field:PIP_Monthly:F_PIP_DATE:DATE2'],
                                                    fields_include_total = 'str:field:PIP_Monthly:V_F_PIP_MONTHLY:DISABILITY_CODE', 
                                                    df_schema = df_schema, 
                                                    geog_folder_label = 'Geography (residence-based)', 
                                                    geog_field_label= 'Country - Region - Local Authority', 
                                                    geog_level_label = 'Local Authority')
# Save the data and annotations
pip['data'].to_csv(output_directory + 'personal_independence_payment_data.csv', index=False)
with open(output_directory + 'pip_annotations.txt', 'w') as f:
    for annotation in pip['annotations'].values():
        f.write(annotation+'\n\n')


# Numbers claiming Attendance Allowance by primary condidtion, date and geography
aa = stat_xplore_table.get_stat_xplore_measure_data(table_headers, 
                                                    schema_headers, 
                                                    measure_id = 'str:count:AA_Entitled:V_F_AA_Entitled', 
                                                    field_ids = [   'str:field:AA_Entitled:F_AA_QTR:DATE_NAME',
                                                                    'str:field:AA_Entitled:V_F_AA_Entitled:DISABLED',
                                                                    'str:field:AA_Entitled:V_F_AA_Entitled:COA_CODE'],
                                                    fields_include_total = 'str:field:AA_Entitled:V_F_AA_Entitled:DISABLED', 
                                                    df_schema = df_schema, 
                                                    geog_folder_label = 'Geography (residence-based)',
                                                    geog_field_label = 'National - Regional - LA - OAs',
                                                    geog_level_label = 'Local Authority')

aa['data'].to_csv(output_directory + 'attendance_allowance_data.csv', index=False)
with open(output_directory + 'aa_annotations.txt', 'w') as f:
    for annotation in aa['annotations'].values():
        f.write(annotation+'\n\n')


# Numbers of national insurance registrations by quarter local authority of residence and broad nationality
nino = stat_xplore_table.get_stat_xplore_measure_data(  table_headers, 
                                                        schema_headers, 
                                                        measure_id = 'str:count:NINO:f_NINO', 
                                                        field_ids = [   'str:field:NINO:f_NINO:QTR',
                                                                        'str:field:NINO:f_NINO:NEWNAT',
                                                                        'str:field:NINO:f_NINO:COUNTY_DISTRICT_UA_2011'],
                                                        fields_include_total = 'str:field:NINO:f_NINO:NEWNAT', 
                                                        df_schema = df_schema, 
                                                        geog_folder_label = 'Location at Registration',
                                                        geog_field_label = 'National - Regional - Admin LA (Northern Ireland Districts included)',
                                                        geog_level_label = 'Local Authority/Northern Ireland District')

nino['data'].to_csv(output_directory + 'nino_data.csv', index=False)
with open(output_directory + 'nino_annotations.txt', 'w') as f:
    for annotation in nino['annotations'].values():
        f.write(annotation+'\n\n')