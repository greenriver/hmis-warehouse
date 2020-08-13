###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterErrorsController < ApplicationController
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @base_name = File.basename(
      importer_log.summary.keys.detect { |v| v == params[:file] },
      '.csv',
    )
    @import = GrdaWarehouse::ImportLog.find_by(importer_log_id: importer_log.id)
    pattern = '%::' + @base_name.downcase
    @errors = importer_log.import_errors.where(HmisCsvTwentyTwenty::Importer::ImportError.arel_table[:source_type].lower.matches(pattern))
    @validations = importer_log.import_validations.where(HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern))
  end
end
