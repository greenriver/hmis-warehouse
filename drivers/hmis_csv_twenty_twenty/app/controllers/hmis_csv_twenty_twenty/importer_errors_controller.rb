###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterErrorsController < ApplicationController
  include HmisCsvTwentyTwenty::ValidationFiltering
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvTwentyTwenty::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.find_by(importer_log_id: importer_log.id)

    @filename = detect_filename

    @errors = importer_log.import_errors.where(HmisCsvTwentyTwenty::Importer::ImportError.arel_table[:source_type].lower.matches(pattern)).page(params[:page])
  end
end
