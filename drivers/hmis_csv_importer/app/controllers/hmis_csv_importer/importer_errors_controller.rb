###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::ImporterErrorsController < ApplicationController
  include HmisCsvImporter::ValidationFiltering
  include HmisCsvController
  before_action :require_can_view_imports!

  def download
    @validations = importer_log.import_validations.preload(:source).
      group_by(&:source_type)
    @errors = importer_log.import_errors.preload(:source).
      group_by(&:source_type)

    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=import_errors_#{importer_log.id}.xlsx"
      end
    end
  end

  private def importer_log
    @importer_log ||= HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)
  end

  def show
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename
    @klass = importable_file_class(version: version(importer_log, @import), filename: @filename)
    @data_source = @import.data_source

    @errors = importer_log.import_errors.where(HmisCsvImporter::Importer::ImportError.arel_table[:source_type].lower.matches(pattern))
    @pagy, @errors = pagy(@errors, items: 200)
  end
end
