###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImporterValidationsController < ApplicationController
  include HmisCsvImporter::ValidationFiltering
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename
    @klass = HmisCsvImporter::Importer::Importer.importable_files[@filename]
    @data_source = @import.data_source

    @validations = importer_log.import_validations.
      where(HmisCsvImporter::HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvImporter::HmisCsvValidation::Base.validation_classes.map(&:name))

    filter_setup

    @validations = @validations.
      where(type: @filters.selected_validation, validated_column: @filters.column).
      preload(:source)
    @pagy, @validations = pagy(@validations, items: 200)
  end

  def download
    importer_log = HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename

    @validations = importer_log.import_validations.
      where(HmisCsvImporter::HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvImporter::HmisCsvValidation::Base.validation_classes.map(&:name))

    @validations.preload(:source)
    render xlsx: 'download', filename: "#{@filename.gsub('.csv', '')}_errors.xlsx"
  end
end
