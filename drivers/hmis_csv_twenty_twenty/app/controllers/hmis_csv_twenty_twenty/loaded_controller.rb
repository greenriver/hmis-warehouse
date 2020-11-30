###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::LoadedController < ApplicationController
  before_action :require_can_view_imports!

  def show
    log = HmisCsvTwentyTwenty::Loader::LoaderLog.find(params[:id].to_i)
    @filename = log.summary.keys.detect { |v| v == params[:file] }
    @import = GrdaWarehouse::ImportLog.find_by(loader_log_id: log.id)
    @klass = HmisCsvTwentyTwenty::Loader::LoaderLog.importable_files[@filename]
    @data = @klass.with_deleted.where(loader_id: log.id).
      order(@klass.hud_key => :asc).
      page(params[:page]).
      per(500)
  end
end
