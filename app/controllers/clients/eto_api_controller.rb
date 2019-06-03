###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class EtoApiController < Window::Clients::EtoApiController
    include ClientPathGenerator
    
    def client_scope
      client_source.destination.joins(source_clients: :data_source)
    end
  
  end
end
