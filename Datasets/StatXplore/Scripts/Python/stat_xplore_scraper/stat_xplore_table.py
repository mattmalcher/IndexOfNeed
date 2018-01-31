# Functions to interact with the 'table' end point of the Stat-Xplore API
import json
import pandas as pd 
import numpy as np 
import requests
import os
import stat_xplore_schema

table_url = 'https://stat-xplore.dwp.gov.uk/webapi/rest/v1/table'


def json_response_to_dataframe(dict_response):
    '''Take input sting of JSON formatted data returned by the Stat-Xplore API table end point and 
    unpack it into a pandas dataframe. The returned dataframe is in a 'long' format with a column for each field (uri and label)
    and a column for the data value.

    Args:
        json_response (dict): Dictionary of data returned by the Stat-Xpore API table end point

    Returns:
        pandas DataFrame: The Stat-Xplore API data formatted as a DataFrame.
    '''

    # Unpack field labels and uris (IDs) plus the labels and uris (IDs) of items within each field.
    field_items = { 'labels':[],
                    'uris':[]}
    field_headers = {   'labels':[],
                        'uris':[]}
    for field in dict_response['fields']:
        # Unpack the labels
        field_items['labels'].append(unpack_field_items(field['items'], item_values_to_return = 'labels'))
        field_headers['labels'].append(field['label'])

        # Unpack the uris
        field_items['uris'].append(unpack_field_items(field['items'], item_values_to_return = 'uris'))
        field_headers['uris'].append(field['uri'])

    measure_uri = dict_response['measures'][0]['uri'] 
    cubes_array = np.array(dict_response['cubes'][ measure_uri]['values'])

    # unpack the data, using the field item values' IDs to index values
    dict_data = unpack_cube_data(field_items['uris'],field_headers['uris'], cubes_array)
    
    df = pd.DataFrame(dict_data)

    # Add in the labels
    final_headers = []
    for i in range(len(field_headers['uris'])):
        # Form lookup dictionary from uri to label
        dict_field_lookup = dict(zip(field_items['uris'][i], field_items['labels'][i]))

        # Create a new labels column by replacing the uris with their labels
        df[field_headers['labels'][i]] = df[field_headers['uris'][i]].replace(dict_field_lookup)

        # Add each header to list so that they are ordered by field type
        final_headers.append(field_headers['uris'][i])
        final_headers.append(field_headers['labels'][i])
    
    # Add the value header
    final_headers.append('value')

    return df.reindex(columns = final_headers)

def unpack_cube_data(labels, headers, cubes_array):
    '''For input lists of the field labels and the array of data, unpak the data assigning the coorect labels to each value.
    Function can unpack 1d,2d and 3d data arrays. THis covers all possible dimensions returned by the stat-xplore API.
    Data is unpacked into a dictionary of tuples.

    Args:
        labels (array of str): A 2d array containing lists of the labels to index data values with
        headers (list of str): A list of the headers for the fields data is indexed by
        cubes_array (multi-dim numpy array): The data values to unpack

    Returns: 
        dict: Dictionary of the labels and the data values.
    '''
    dict_data = {}
    for header in headers:
        dict_data[header] = []
    dict_data['value'] = []

    cube_shape = cubes_array.shape  

    # Unpacking 1d
    if len(cube_shape) == 1:
        assert len(labels[0] == len(cubes_array[:]))
        dict_data[headers[0]] += (labels[0])
        dict_data['value'] += (list(cubes_array[:]))
    # Unpacking 2d data
    elif len(cube_shape) == 2:
        assert len(labels[0]) == cube_shape[0]
        assert len(labels[1]) == cube_shape[1]
        for x in range(cube_shape[0]):
            assert len(labels[1][:]) == len(cubes_array[x,:])
            dict_data[headers[0]] += ([labels[0][x]]*cube_shape[1])
            dict_data[headers[1]] += (labels[1][:])
            dict_data['value'] += (list(cubes_array[x,:]))
    # Unpacking 3d data
    elif len(cube_shape) == 3:
        assert len(labels[0]) == cube_shape[0]
        assert len(labels[1]) == cube_shape[1]
        assert len(labels[2]) == cube_shape[2]
        for x in range(cube_shape[0]):
            for y in range(cube_shape[1]):
                assert len(labels[2][:]) == len(cubes_array[x,y,:])
                dict_data[headers[0]] += ([labels[0][x]]*cube_shape[2])
                dict_data[headers[1]] += ([labels[1][y]]*cube_shape[2])
                dict_data[headers[2]] += (labels[2][:])
                dict_data['value'] += list(cubes_array[x,y,:])
    return dict_data

# Could change this function to unpack both ids and labels, return multidimensional array
def unpack_field_items(field_items, item_values_to_return = 'labels'):
    '''The Stat-Xplore API returns fie;d values as an array of arrays, ie [ [value1], [value2], ...].
    This function unpacks field values into a 1d array so that they can be parsed into a pandas DataFrame.

    Args:
        field_items (dict): Dictionary of field items. Each field has 'labels' and 'uris' items under which the values are stored

    Kwargs:
        item_values_to_return (str): Defaults to 'labels' sets which itemm type to unpack the values from.

    Returns:
        list: The unpacked field values
    '''
    item_values = []

    if item_values_to_return not in ['labels','uris']:
        print("unpack_field_items: Failed to unpack items. Unrecognised value type to return. Must be either 'labels' or 'uris'")

    # Get the label or uri from each field item value
    # Where field items are the 'Total' for all field values, a uri isn't given. Use the label in this instance
    for item in field_items:
        if item['type'] == 'Total':
            item_values.append(item['labels'][0])
        else:
            item_values.append(item[item_values_to_return][0])
    return item_values


def get_stat_xplore_measure_data(table_headers, schema_headers, measure_id, field_ids = None, fields_include_total = None, df_schema = None, geog_folder_label = 'Geography (residence-based)', geog_field_label= 'National - Regional - LA - OAs', geog_level_label = 'Local Authority'):
    '''For an input measure ID and field IDs as well as the labels for the geography folder, field and level to get data for 
    build that dictionary of data to send to the Stat-Xplore table end point to request data.

    Args:
        table_headers (dict): The headers to uses for the request to the table endpoint of the Stat-Xplore API
        schema_headers (dict): The headers to uses for the request to the schema endpoint of the Stat-Xplore API
        measure_id (str): The id of the measure to request data for. This is the dataset, such as Attendence Allowance claimants, 
            that data is returned for

    Kwargs:
        field_ids (list of str, None): Default None. The field IDs of the fields to in intersect they data by
        fields_include_total (str or list of str): The field IDs of the fields which will include the total across all field values in the returned data.
            This cannot be the date field.
        df_schema (pandas DataFrame, None): Default to None. A DataFrame of the Stat-Xplore schema
        geog_folder_label (str): Defaults to 'Geography (residence-based)'. The label of the geography folder to get geography recodes from
        geog_field_label (str): Defaults tp 'National - Regional - LA - OAs'. The label of the geography field to get geography recodes from.
        geog_level_label (str): Defaults to 'Local Authority'. The label of the level (ie LAs, LSOAs etc) to get recodes for

    Returns:
        dict: Dictionary with the following items: 'data' - a pandas Data Frame of the request data, or None if request was unsucessfull; 
                'annotations' - A string of the annotations accoumpanying the data. Contains info on what the data show.

    '''

    # Build request body
    body = build_request_body(table_headers, schema_headers, measure_id, field_ids = field_ids, fields_include_total = fields_include_total, df_schema = df_schema, geog_folder_label = geog_folder_label, geog_field_label = geog_field_label, geog_level_label = geog_level_label)

    # Request data
    response_dict = request_table(table_headers, json.dumps(body))

    if response_dict['success'] == True:
        json_data = response_dict['response'].json()

        # Format data into dataframe
        df_data = json_response_to_dataframe(json_data)

        # Get database annotations (footnaotes)
        database_annotation_keys = json_data['database']['annotationKeys']
        database_annotations = {}
        for key in database_annotation_keys:
            database_annotations[key] = json_data['annotationMap'][key]

        return {'data': df_data, 'annotations':database_annotations}
    else:
        return {'data':None, 'annotations':None}


def build_request_body(table_headers, schema_headers, measure_id, field_ids = None, fields_include_total = None, df_schema = None, geog_folder_label = 'Geography (residence-based)', geog_field_label= 'National - Regional - LA - OAs', geog_level_label = 'Local Authority'):
    '''For an input measure ID and field IDs as well as the labels for the geography folder, field and level to get data for 
    build that dictionary of data to send to the Stat-Xplore table end point to request data.

    Args:
        table_headers (dict): The headers to uses for the request to the table endpoint of the Stat-Xplore API
        schema_headers (dict): The headers to uses for the request to the schema endpoint of the Stat-Xplore API
        measure_id (str): The id of the measure to request data for. This is the dataset, such as Attendence Allowance claimants, 
            that data is returned for

    Kwargs:
        field_ids (list of str, None): Default None. The field IDs of the fields to in intersect they data by
        fields_include_total (str or list of str): The field IDs of the fields which will include the total across all field values in the returned data
            This cannot be the date field.
        df_schema (pandas DataFrame, None): Default to None. A DataFrame of the Stat-Xplore schema
        geog_folder_label (str): Defaults to 'Geography (residence-based)'. The label of the geography folder to get geography recodes from
        geog_field_label (str): Defaults tp 'National - Regional - LA - OAs'. The label of the geography field to get geography recodes from.
        geog_level_label (str): Defaults to 'Local Authority'. The label of the level (ie LAs, LSOAs etc) to get recodes for

    Returns:
        dict: Dictionary with keys 'database', 'measures', 'recodes', 'dimensions'. This dictionary is sent to the stat-xplore API when requesting data

    '''

    # Get database id
    database_id = 'str:database:' + measure_id.split(':')[-2]

    database_value = database_id

    measures_values = get_measures_request_body(measure_id)

    recodes_values = get_geography_recodes_request_body(schema_headers, database_id, geog_folder_label = geog_folder_label, geog_field_label= geog_field_label, geog_level_label = geog_level_label, df_schema = df_schema)

    dimensions_values = get_dimensions_body(schema_headers, database_id, field_ids, df_schema = df_schema)

    # Add in geography recode field id to the dimensions
    dimensions_values = dimensions_values + [[i] for i in list(recodes_values.keys())]

    # Add in the field totals to the recodes so that the returned data includes field totals (ie total for all genders)
    if fields_include_total is not None:
        fields_include_total = [fields_include_total] if isinstance(fields_include_total, str) else fields_include_total
        # Ensure that existing recode items are not changed
        # The dimension id is the element within the array
        for field in fields_include_total:
            if field in recodes_values.keys():
                continue
            recodes_values[field] = {'total':True}

    body = {'database':database_value,
            'measures':measures_values,
            'recodes': recodes_values,
            'dimensions':dimensions_values}

    return body

def get_dimensions_body(schema_headers, database_id, field_ids, df_schema = None):
    '''Format the fields IDs to the required format for the dimensions section of the data request body. 
    If field IDs is None, get all available fields for the given database.

    Args:
        schema_headers (dict): The headers of the request.
        database_id (str): The ID of the database to get dimension fields for.
        field_ids (str or list of str or None): The fields to use as dimensions in the data request
        df_schema (pandas DataFrame or None): The stat-xplore schema

    Returns:
        list: The field ids to use as dimensions properly formatted

    '''

    all_field_ids_dict = stat_xplore_schema.get_database_fields(schema_headers, database_id, df_schema = df_schema)
    all_field_ids = list(all_field_ids_dict.values())
    
    if field_ids is None:
        return all_field_ids

    field_ids = [field_ids] if isinstance(field_ids, str) else field_ids
    dimensions_array = [[i] for i in field_ids if i in all_field_ids]

    return dimensions_array 

def get_measures_request_body(measure_ids):
    '''Given an input measure ID or list of measure IDs return a dictionary of the format:
    {'measures':['measure_id_1','measure_id_2', ...]}

    Args:
        measure_ids (str or list of str): The measure IDs to format

    Returns:
        list: A list of measure ids
    '''

    measure_ids = [measure_ids] if isinstance(measure_ids, str) else measure_ids

    return measure_ids

def get_geography_recodes_request_body(schema_headers, database_id, geog_folder_label = 'Geography (residence-based)', geog_field_label= 'National - Regional - LA - OAs', geog_level_label = 'Local Authority', df_schema = None, check_cache = False, schema_filename = 'schema.csv'):
    '''A wrapped function that gets the requested geography recodes and passes them to a functino that formats tha recodes into the
    dictionary format required for requesting data.
    
    Args:
        schema_headers (dict): The headers of the request
        database_id (str): The ID of the database to get dimension fields for
    
    Kwargs:
        geog_folder_label (str): Defaults to 'Geography (residence-based)'. The label of the geography folder to get geography recodes from
        geog_field_label (str): Defaults tp 'National - Regional - LA - OAs'. The label of the geography field to get geography recodes from
        geog_level_label (str): Defaults to 'Local Authority'. The label of the level (ie LAs, LSOAs etc) to get recodes for

    '''

    # Get the recodes
    recodes_dict = stat_xplore_schema.geography_recodes_for_geog_folder_geog_level(schema_headers, database_id, geog_folder_label, geog_field_label, geog_level_label, df_schema, check_cache, schema_filename)

    # Format the recodes
    recodes_data = format_recodes_for_api(recodes_dict, include_total = True)

    return recodes_data

def format_recodes_for_api(recodes_dict, include_total = True):
    '''Takes input dictionary of recode field id:list of desired re code values
    and formats this into a valid recodes object for reuesting table data from the API.
    A valid recodes objects is a dictionary with recode field ids as keys. Each id looks to 
    another dictionary oject with a 'map' key and a 'total' key. Desired recodes are set as an array
    of values, each in their own array, within the map object.

    EG

    'field_id':{  'map':[
                    ['field_value_1'],
                    ['field_value_2'],
                    ['field_value_3']
                    ],
                'total': true}
    Args:
        recodes_dict (dict): A dictionary with the recode field id as a key and a list of recode field
            values as the item.

    Kwargs:
        include_total (bool): Default False. Set whether or not to set the 'total' option to 'true' or 'false'
            This controls whether data returned by the request includes a total across all recode field values.

    Returns:
        dict: Recode field id and field values in the required format
    '''

    # Assumes there is only one recode field id
    field_id = list(recodes_dict.keys())[0]

    field_values = recodes_dict[field_id]

    # Convert values into an array of arrays
    map_values = [ [i] for i in field_values ]

    if include_total == False:
        total_value = False
    else:
        total_value = True
    # Combine into single dict
    recodes_data = {field_id:{
                                'map': map_values,
                                'total':total_value
                            }
                    }
    #  Might need to convert into json object (ie just text)
    return recodes_data

def gen_xyz(x_max, y_max, z_max):
    '''Generator. For input integers x_max, y_max, z_max iterate over each one and yield
    a tuple of (x,y,z) coordinates.

    Args:
        x_max (int)
        y_max (int)
        z_max (int)

    Returns:
        tuple: (x,y,z) coordinates
    '''
    for x in range(x_max):
        for y in range(y_max):
           for z in range(z_max):
                    yield x,y,z

def request_table(table_headers, table_data):
    '''Send request for table to API. Check request was successful.

    Args:
        url (str): The url of the request.
        table_headers (dict): The headers of the request.
    '''
    global table_url
    table_response = requests.post(table_url, headers = table_headers, data = table_data)

    # Check that request was successful. If not print message and exit.
    if table_response.raise_for_status() is not None:
        print("Unsuccessful request to url:{}\nCheck url and API key.".format(url))
        print("Response status:\n{}".format(table_response.raise_for_status()))
        return {'success':False, 'response':None}
    else:
        return {'success':True, 'response':table_response}
