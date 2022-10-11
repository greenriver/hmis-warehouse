# Rails.logger.debug "Running initializer in #{__FILE__}"

require 'zip'
# Overwrite when extracting by default
Zip.on_exists_proc = true
