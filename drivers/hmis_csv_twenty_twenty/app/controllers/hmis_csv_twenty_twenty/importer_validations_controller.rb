###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterValidationsController < ApplicationController
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.find_by(importer_log_id: importer_log.id)

    @filename = HmisCsvTwentyTwenty::Importer::Importer.importable_files_map.keys.detect { |v| v == params[:file] }
    pattern = '%::' + HmisCsvTwentyTwenty::Importer::Importer.importable_files_map[@filename].downcase

    @validations = importer_log.import_validations.where(HmisCsvValidation::Base.arel_table[:source_type].lower.matches(pattern)).page(params[:page])
  end
end
