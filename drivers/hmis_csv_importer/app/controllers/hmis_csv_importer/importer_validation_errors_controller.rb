###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::ImporterValidationErrorsController < ApplicationController
  include HmisCsvImporter::ValidationFiltering
  include HmisCsvController
  before_action :require_can_view_imports!

  def show
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename
    @klass = HmisCsvImporter::Importer::Importer.importable_files(version(importer_log, @import))[@filename]
    @data_source = @import.data_source

    @validations = importer_log.import_validations.
      where(HmisCsvImporter::HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvImporter::HmisCsvValidation::Base.error_classes.map(&:name))

    filter_setup

    @validations = @validations.
      where(type: @filters.selected_validation, validated_column: @filters.column).
      preload(:source)
    @pagy, @validations = pagy(@validations, items: 200)
  end

  private def importer_log
    @importer_log ||= HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)
  end
end
