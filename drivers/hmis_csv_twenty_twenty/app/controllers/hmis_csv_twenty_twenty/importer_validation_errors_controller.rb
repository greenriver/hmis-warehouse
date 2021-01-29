###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterValidationErrorsController < ApplicationController
  include HmisCsvTwentyTwenty::ValidationFiltering
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.find_by(importer_log_id: importer_log.id)

    @filename = detect_filename

    @validations = importer_log.import_validations.
      where(HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).
      where(type: HmisCsvValidation::Base.error_classes.map(&:name))

    filter_setup

    @validations = @validations.
      where(type: @filters.selected_validation, validated_column: @filters.column).
      preload(:source).
      page(params[:page])
  end
end
