###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::LoadedController < ApplicationController
  before_action :require_can_view_imports!

  def show
    log = HmisCsvImporter::Loader::LoaderLog.find(params[:id].to_i)
    @filename = log.summary.keys.detect { |v| v == params[:file] }
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(loader_log_id: log.id)
    @klass = HmisCsvImporter::Loader::LoaderLog.loadable_files[@filename]
    @data = @klass.where(loader_id: log.id).
      order(@klass.hud_key => :asc)
    @data = @data.with_deleted if @klass.paranoid?
    @data = @data.page(params[:page]).per(500)
  end
end
