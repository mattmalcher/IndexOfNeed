##
## Initialisation script - common to all Index of Need datasets (and potentially case studies)
##
dir_data_in = "../../Source Data"
dir_data_out = "../../Processed Data"

# create the data folders if they don't exist
if (!dir.exists(dir_data_in))
  dir.create(dir_data_in)

if (!dir.exists(dir_data_out))
  dir.create(dir_data_out)
