###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class FilesController < IndividualPatientController
    include AjaxModalRails::Controller
    include ClientPathGenerator

    before_action :set_client
    before_action :set_hpc_patient

    def index
      @files = @patient.health_files.order(created_at: :desc)
      @blank_files = GrdaWarehouse::PublicFile.known_health_locations.to_a.map do |location, title|
        { title: title, url: GrdaWarehouse::PublicFile.url_for_location(location) }
      end
    end

    def show
      @file = @patient.health_files.find(params[:id].to_i)
      filename = @file.file&.file&.filename&.to_s || 'health_file'
      send_data(
        @file.content,
        type: @file.content_type,
        filename: filename,
      )
    end

    protected def title_for_show
      "#{@client.name} - Health - Files"
    end
  end
end
