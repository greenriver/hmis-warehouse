module HealthFileController
  extend ActiveSupport::Concern

  included do

    def upload
      @upload_object.assign_attributes(upload_params)
      if @upload_object.health_file&.new_record?
        @upload_object.health_file.set_calculated!(current_user.id, @client.id)
      end
      unless @upload_object.save
        flash[:error] = 'No file was uploaded!  If you are attempting to attach a file, be sure it is in PDF format.'
      end
      respond_with @upload_object, location: @location
    end

    def download
      @file = @upload_object.health_file
      send_data @file.content,
        type: @file.content_type,
        filename: File.basename(@file.file.to_s)
    end

    def remove_file
      if @upload_object.health_file.present?
        @upload_object.health_file.destroy
      end
      @upload_object.build_health_file
      respond_with @upload_object, location: @location
    end

    private

    def upload_params
      params.require(:health_file).permit(
        health_file_attributes: [
          :id,
          :file,
          :file_cache
        ]
      )
    end

  end

end