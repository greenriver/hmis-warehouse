###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::LoadedController < ApplicationController
  include HmisCsvController
  before_action :require_can_view_imports!

  def show
    log = HmisCsvImporter::Loader::LoaderLog.find(params[:id].to_i)
    @filename = log.summary.keys.detect { |v| v == params[:file] }

    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(loader_log_id: log.id)
    redirect_to import_path(@import) and return unless @filename.present?

    @klass = HmisCsvImporter::Loader::LoaderLog.loadable_files(version(log, @import))[@filename]

    @data = @klass.where(loader_id: log.id).
      order(@klass.hud_key => :asc)
    @data = @data.with_deleted if @klass.paranoid?
    @pagy, @data = pagy(@data, items: 500)
  end
end
