###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImporterErrorsController < ApplicationController
  include HmisCsvImporter::ValidationFiltering
  before_action :require_can_view_imports!

  def show
    importer_log = HmisCsvImporter::Importer::ImporterLog.find(params[:id].to_i)
    @import = GrdaWarehouse::ImportLog.viewable_by(current_user).
      find_by(importer_log_id: importer_log.id)

    @filename = detect_filename
    @klass = HmisCsvImporter::Importer::Importer.importable_files[@filename]
    @data_source = @import.data_source

    @errors = importer_log.import_errors.where(HmisCsvImporter::Importer::ImportError.arel_table[:source_type].lower.matches(pattern)).
      page(params[:page]).
      per(200)
  end
end
