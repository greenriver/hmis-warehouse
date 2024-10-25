# Rails.logger.debug "Running initializer in #{__FILE__}"
require 'pagy/extras/bootstrap'
require 'pagy/extras/array'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 25 # items per page
Pagy::DEFAULT[:overflow] = :last_page
