Rails.logger.debug "Running initializer in #{__FILE__}"
require 'pagy/extras/bootstrap'

Pagy::DEFAULT[:items] = 25 # items per page
