# Rails.logger.debug "Running initializer in #{__FILE__}"
require 'pagy/extras/bootstrap'
require 'pagy/extras/array'

Pagy::DEFAULT[:items] = 25 # items per page
