###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Health
  class FilesController < IndividualPatientController
    include PjaxModalController
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
      send_data(
        @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s),
      )
    end

    protected def title_for_show
      "#{@client.name} - Health - Files"
    end
  end
end
