###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterExtensionsController < ApplicationController
  before_action :require_can_view_imports!

  def show
    @data_source = GrdaWarehouse::DataSource.find(params[:id].to_i)
  end
end
