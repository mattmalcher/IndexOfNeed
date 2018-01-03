import requests
import pandas as pd 
import os

schema_url = 'https://stat-xplore.dwp.gov.uk/webapi/rest/v1/schema'

def get_full_schema(schema_headers, types_to_include = ["FOLDER","DATABASE","MEASURE","FIELD"], check_cache = False, schema_filename = '.\stat_xplore_lib\schema\schema.csv'):
    '''Get the schema information of all elements of the Stat-Xplore schema but sratting at the root 
    folder and iterating through the schema tree.

    Args:
        schema_headers (dict): The headers to use in the html request to the stat-xplore API.

    Kwargs:
        types_to_include (list of str): Defaults to ["FOLDER","DATABASE","MEASURE","FIELD"]. 
            The schema element types to include in the schema dataframe
        check_cache (bool): Default False. Set whether to check the cached schema csv for schema information
        cache_filename (str): Default '.\stat_xplore_lib\schema\schema.csv'. The filename of the chached schema
    '''

    # Get chema info for the root folder
    root_reponse = request_schema(schema_headers)
    if root_reponse['success'] == False:
        return
    root_json = root_reponse['response'].json()

    # Remove the 'children' key of the schema - we only want to record the 'id', 'type', 'label' and 'location' schema information
    del root_json['children']

    # Initialise full schema dataframe with the schema infomation of the root folder
    df_full_schema = pd.DataFrame([root_json])

    # Start loop to interate over all parent schema items
    still_to_map = df_full_schema
    while len(still_to_map) >0:

        new_schema = get_lower_tier_schema_from_upper_tier_schema(still_to_map, schema_headers, check_cache, cache_filename = schema_filename)

        # Only get children schemas desired types in the resulting schema. 
        # Eg exclude value sets such as all geographies (this can take a while to get)
        still_to_map = new_schema.loc[new_schema['type'].isin(types_to_include)]

        df_full_schema = pd.concat([df_full_schema, new_schema], join = 'outer')

        # Save the schema as we go
        df_full_schema.to_csv(schema_filename, index=False, encoding = 'utf-8')

    return df_full_schema

        

def get_lower_tier_schema_from_upper_tier_schema(df_parent_schema, schema_headers, check_cache = False, cache_filename = '.\stat_xplore_lib\schema\schema.csv'):
    '''Function to loop through each of the parent elements of the upper tier schema and get the schema
    of the children of each one. Children schemas are combined together and returned.

    Args:
        df_parent_schema (pandas DataFrame): The parent schema of teh children schemas to return
        schema_headers (dict): The headers to use in the html request to the stat-xplore API.

    Kwargs:
        check_cache (bool): Default False. Check local directory for schema details.
        cache_filename (str): Default '.\stat_xplore_lib\schema\schema.csv'. The filename of the cached schema details 
                                to check for.
    '''
    # Get teh urls of each of the parent items
    parent_locations = df_parent_schema['location'].unique()

    # initialise the lower tier schema
    df_lower_tier_schema = pd.DataFrame()

    # Iterate over parent items and get children schema
    for location in parent_locations:
        children_schema_result = get_children_schema_of_url(location, schema_headers, check_cache, cache_filename)
        if children_schema_result['success'] == False:
            print('Faield to get children schema for location {}'.format(location))
            continue

        df_lower_tier_schema = pd.concat([df_lower_tier_schema, children_schema_result['schema']], join = 'outer')


    return df_lower_tier_schema

def get_children_schema_of_url(url, schema_headers, check_cache = False, cache_filename = '.\stat_xplore_lib\schema\schema.csv'):
    '''Given a url of a Stat-xplore schema item, get the schema details of the children (component) items. 
    The schema for each chils contains id, label, location(url) and type fields.The id of the parent element 
    s also included in the output schema.

    Args:
        url (str): The url of the schema item to get the children schema details of.
        schema_headers (dict): The headers to use in the html request to the stat-xplore API.

    Kwargs:
        check_cache (bool): Default False. Check local directory for schema details.
        cache_filename (str): Default '.\stat_xplore_lib\schema\schema.csv'. The filename of the cached schema details 
                                to check for.
    '''

    output = {'success':False, 'schema':None, 'from_cache':False}

    # Check for saved schema
    if (check_cache == True) & (os.path.exists(cache_filename) == True):

        try:
            df_full_schema = pd.read_csv(cache_filename, encoding = 'utf-8')
            parent_id = df_full_schema.loc[ df_full_schema['location'] == url, 'id'].values[0]
            df_schema = df_full_schema.loc[df_full_schema['parent_id'] == parent_id]
            assert len(df_schema) != 0

            return {'success':True,'schema':df_schema, 'from_cache':True}
        except Exception as err:
            print(err)
            print('Unable to load cached schema. Requesting from API instead.')
            df_schema = pd.DataFrame()
    else:
        df_schema = pd.DataFrame()


    # If the schema dataframe is empty (which it will be if the cache wasn't successfully checked)
    # make request to the API to get the schema details
    if len(df_schema) == 0:

        schema_response = request_schema(schema_headers, url = url)
        if schema_response['success'] == False:
            return output

        # If this far, request to API was successfull and we should have schema information
        # Create dataframe with schema info of children elements
        schema_response_json = schema_response['response'].json()

        # Will there always be a children element?
        df_schema = pd.DataFrame(schema_response_json['children'])
        df_schema['parent_id'] = schema_response_json['id']

    return {'success':True,'schema':df_schema, 'from_cache':False}

def request_schema(schema_headers, url = schema_url):
    '''Send request for schema to API. Check request was successful.

    Args:
        url (str): The url of the request.
        schema_headers (dict): The headers of the request.
    '''
    schema_response = requests.get(url, headers = schema_headers)

    # Check that request was successful. If not print message and exit.
    if schema_response.raise_for_status() is not None:
        print("Unsuccessful request to url:{}\nCheck url and API key.".format(url))
        print("Response status:\n{}".format(schema_response.raise_for_status()))
        return {'success':False, 'response':None}
    else:
        return {'success':True, 'response':schema_response}


# Functions for getting recodes for a database item
def geography_recodes_for_geog_folder_geog_level(schema_headers, database_id, geog_folder_label = 'Geography (residence-based)', geog_field_label= 'National - Regional - LA - OAs', geog_level_label = 'Local Authority', df_schema = None, check_cache = False, schema_filename = '.\stat_xplore_lib\schema\schema.csv'):
    '''Get the geography recodes (geographic codes with additional formatting specifying which databse they refer to)
    for a given database (for example 'CA_In_Payment' ). Recodes can be used to request data for specific geographies, eg 
    all local authorities.

    Args:
        schema_headers (dict): The headers of the request.
        database_id (str): The database id to get recode for

    Kwargs:
        df_schema (pandas DataFrame, None): Default None. The schema. If None, the required schema elements are erquested from the API
        geog_folder_label (str): Default 'Geography (residence-based)'. The geography folder label containing the geography recodes
        geog_field_label (str): Default 'National - Regional - LA - OAs'. The geography field label, eg 'National - Regional - LA - OAs'
        geog_level_label (str): Defaukt 'Local Authority'. The geographic level label to get recodes for (eg lcoal authority or LSOA)
        df_schema (pandas DataFrame, None): Default None. The stat-xplore schema
        check_cache (bool): Default '.\stat_xplore_lib\schema\schema.csv'. Default False. Set whether to check the cached schema csv for schema information
        cache_filename (str): The filename of the chached schema

    Returns:
        dict: key is str id of the geography field. Value is list of str geography field values
    '''

    # Check if schema was passed in. If not get schema
    if df_schema is None:
        df_schema = get_full_schema(schema_headers, check_cache = check_cache, schema_filename = schema_filename)

    # Get the id of the geog folder requested
    geog_folder_id = df_schema.loc[(df_schema['parent_id'] == database_id) & (df_schema['label'] == geog_folder_label), 'id'].values[0]

    # Get id of the geography recodes folder
    geog_field_id = df_schema.loc[ (df_schema['parent_id'] == geog_folder_id) & (df_schema['label'] == geog_field_label), 'id'].values[0]

    # Get location of the value set of geography recodes
    # here we sectect which geographic level we want (eg, OA, LA, LSOA, etc), and the according valueset location is returned.
    geog_field_valueset_loc = df_schema.loc[ (df_schema['parent_id'] == geog_field_id) & (df_schema['label'] == geog_level_label), 'location'].values[0]


    # Call function to get recodes given a valueset location
    geog_recodes = get_recodes_from_valueset_location(schema_headers, geog_field_valueset_loc)

    return {geog_field_id:geog_recodes}


def get_recodes_from_valueset_location(schema_headers, valueset_loc):
    '''Query the API schema to get the set of recodes that are located within the input valueset

    Args:
        schema_headers (dict): The headers of the request.
        valueset_loc (str): Localtion of the valueset to return recodes from

    Returns:
        recodes (dict): recodes dictionary with key being the valueset id of the recodes and the item 
                        being a list of recodes
    '''


    valueset_response = request_schema(schema_headers, url = valueset_loc)

    if valueset_response['success'] == False:
        return None

    valueset_json = valueset_response['response'].json()

    df_valueset = pd.DataFrame(valueset_json['children'])

    return df_valueset['id'].tolist()

def get_database_fields(schema_headers, database_id, df_schema = None, check_cache = False, cache_filename = '.\stat_xplore_lib\schema\schema.csv'):
    '''Given a database ID, return the ids of the fields within that database. Note that this function does not
    return fields that are contained within folders withing the database, for example the geography fields.
    
    Args:
        schema_headers (dict): The headers of the request.
        database_id (str): The ID of the database to get fields for

    Kwargs:
        df_schema (pandas DataFrame, None): Default None. The stat-xplore schema
        check_cache (bool): Default False. Set whether to check the cached schema csv for schema information
        cache_filename (str): Default '.\stat_xplore_lib\schema\schema.csv'. The filename of the chached schema

    Returns:
        dict: The field labels as keys, the field ids as values
    '''

    if df_schema is None:
        df_schema = get_full_schema(schema_headers,check_cache = check_cache, schema_filename = cache_filename)

    # Get fields beloning to parent
    fields_dict = df_schema.loc[ (df_schema['parent_id'] == database_id) & (df_schema['type'] == 'FIELD'), ['id', 'label']].set_index('label').to_dict()

    return fields_dict['id']