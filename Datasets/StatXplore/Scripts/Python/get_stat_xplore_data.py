# Script for getting Stat-Xplore data using the stat_xplore scraper libraries to access the Stat-Xplore API
import sys
sys.path.append('.\stat_xplore_lib')
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

APIKey = '65794a30655841694f694a4b563151694c434a68624763694f694a49557a49314e694a392e65794a7063334d694f694a7a644849756333526c6247786863694973496e4e3159694936496d39696153357a59584a6e623235705147396a63326b7559323875645773694c434a70595851694f6a45314d5451354f5467304e7a5173496d46315a434936496e4e30636935765a47456966512e5f65352d586f344a7356466d4945546d657a42587339386d7a793738456c6e4e7061643948706e6270646f'
table_headers = {'APIKey':APIKey,
                'Content-Type':'applciation/json'}
schema_headers = {'APIKey':APIKey}


# Get the Stat-Xplore schema. This is used to find the codes of fields and values when getting data
# This takes a while. Need to fix encoding issue so user can read in saved schema instead of querying API for new one
df_schema = stat_xplore_schema.get_full_schema(schema_headers)

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
ca['data'].to_csv('carers_allowance_data.csv', index=False)
with open('carers_allowance_annotations.txt', 'w') as f:
    for annotation in ca['annotations'].values():
        f.write(annotation+'\n\n')