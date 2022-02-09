###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFileController
  extend ActiveSupport::Concern

  included do
    def upload
      @upload_object.assign_attributes(upload_params)
      @upload_object.health_file.set_calculated!(current_user.id, @client.id) if @upload_object.health_file&.new_record?
      flash[:error] = 'No file was uploaded!  If you are attempting to attach a file, be sure it is in PDF format.' unless @upload_object.save
      respond_with @upload_object, location: @location
    end

    def download
      @file = @upload_object.health_file
      filename = @file.file&.file&.filename&.to_s || 'health_file'
      send_data(
        @file.content,
        type: @file.content_type,
        filename: filename,
      )
    end

    def remove_file
      @upload_object.health_file.destroy if @upload_object.health_file.present?
      @upload_object.build_health_file
      respond_with @upload_object, location: @location
    end

    private

    def upload_params
      params.require(:health_file).permit(
        health_file_attributes: [
          :id,
          :file,
          :file_cache,
        ],
      )
    end
  end
end
