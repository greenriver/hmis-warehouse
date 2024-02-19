###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterValidationsController < ApplicationController
  include HmisCsvTwentyTwenty::ValidationFiltering
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename
    @klass = HmisCsvTwentyTwenty::Importer::Importer.importable_files[@filename]
    @data_source = @import.data_source

    @validations = importer_log.import_validations.
      where(HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvValidation::Base.validation_classes.map(&:name))

    filter_setup

    @validations = @validations.
      where(type: @filters.selected_validation, validated_column: @filters.column).
      preload(:source)
    @pagy, @validations = pagy(@validations, items: 200)
  end

  def download
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename

    @validations = importer_log.import_validations.
      where(HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvValidation::Base.validation_classes.map(&:name))

    @validations.preload(:source)
    render xlsx: 'download', filename: "#{@filename.gsub('.csv', '')}_errors.xlsx"
  end
end
