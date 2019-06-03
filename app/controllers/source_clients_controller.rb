###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class SourceClientsController < Window::SourceClientsController
  include ClientPathGenerator
  
  def redirect_to_path
    client_path(@destination_client)
  end
end