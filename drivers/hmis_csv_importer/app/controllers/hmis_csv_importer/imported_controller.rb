###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::ImportedController < ApplicationController
  include HmisCsvController
  before_action :require_can_view_imports!

  def show
    log = HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)

    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: log.id)
    @filename = @import.files.detect { |_, v| v == params[:file] }&.last
    @klass = importable_file_class(version: version(log, @import), filename: @filename)
    @data = @klass.where(importer_log_id: log.id).
      order(@klass.hud_key => :asc)
    @pagy, @data = pagy(@data, items: 500)
  end
end
