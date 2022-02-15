###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::LoaderErrorsController < ApplicationController
  before_action :require_can_view_imports!

  def show
    loader_log = HmisCsvImporter::Loader::LoaderLog.find(params[:id].to_i)
    @filename = loader_log.summary.keys.detect { |v| v == params[:file] }
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(loader_log_id: loader_log.id)
    @errors = loader_log.load_errors.where(file_name: @filename).page(params[:page])
  end
end
