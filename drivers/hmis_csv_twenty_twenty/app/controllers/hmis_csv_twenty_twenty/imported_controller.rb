###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::ImportedController < ApplicationController
  before_action :require_can_view_imports!

  def show
    log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @filename = HmisCsvTwentyTwenty::Importer::Importer.importable_files_map.keys.detect { |v| v == params[:file] }
    @import = GrdaWarehouse::ImportLog.find_by(importer_log_id: log.id)
    @klass = HmisCsvTwentyTwenty::Importer::Importer.importable_files[@filename]
    @data = @klass.where(importer_log_id: log.id).
      order(@klass.hud_key => :asc).
      page(params[:page]).
      per(500)
  end
end
