###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterRestartsController < ApplicationController
  before_action :require_can_view_imports!

  def update
    @import = GrdaWarehouse::ImportLog.find(params[:id].to_i)
    @import.update(completed_at: nil)
    importer_log = @import.importer_log
    importer_log.update(status: :resuming, completed_at: nil)
    ::Importing::HudZip::ResumeHmisTwentyTwentyJob.perform_later(import_id: @import.id)
    flash[:notice] = "Resuming import for #{@import.data_source.name}"
    redirect_to(data_source_uploads_path(data_source_id: @import.data_source_id))
  end
end
