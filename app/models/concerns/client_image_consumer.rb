###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientImageConsumer
  extend ActiveSupport::Concern
  included do
    has_many :client_files unless respond_to?(:client_files)
    has_many :source_eto_client_lookups, through: :source_clients, source: :eto_client_lookups

    # finds an image for the client. there may be more then one available but this
    # method will select one more or less at random. returns no_image_on_file_image
    # if none is found. returns that actual image bytes
    # FIXME: invalidate the cached image if any aspect of the client changes
    def image(cache_for = 10.minutes) # rubocop:disable Lint/UnusedMethodArgument
      return nil unless GrdaWarehouse::Config.get(:eto_api_available)

      # Use an uploaded headshot if available
      faked_image_data = local_client_image_data || fake_client_image_data
      return faked_image_data unless Rails.env.production?

      # Use the uploaded client image if available, otherwise use the API, if we have access
      image_data = local_client_image_data
      return image_data if image_data
      return nil unless GrdaWarehouse::Config.get(:eto_api_available)

      api_configs = EtoApi::Base.api_configs
      source_eto_client_lookups.detect do |c_lookup|
        api_key = api_configs.select { |_k, v| v['data_source_id'] == c_lookup.data_source_id }&.keys&.first
        return nil unless api_key.present?

        api ||= EtoApi::Base.new(api_connection: api_key).tap(&:connect) rescue nil # rubocop:disable Style/RescueModifier
        image_data = api.client_image( # rubocop:disable Style/RescueModifier
          client_id: c_lookup.participant_site_identifier,
          site_id: c_lookup.site_id,
        ) rescue nil
        (image_data && image_data.length.positive?) # rubocop:disable Style/SafeNavigation
      end

      set_local_client_image_cache(image_data)
      image_data
    end

    # These need to be flagged as available in the Window. Since we cache these
    # in the file-system, we'll only show those that would be available to people
    # with window access
    def local_client_image_data
      headshot = uploaded_local_image
      return headshot.as_thumb if headshot

      local_client_image_cache&.content
    end

    def fake_client_image_data
      gender = if self[:Male].in?([1]) then 'male' else 'female' end
      age_group = if age.blank? || age > 18 then 'adults' else 'children' end
      image_directory = File.join('public', 'fake_photos', age_group, gender)
      available = Dir[File.join(image_directory, '*.jpg')]
      image_id = "#{self.FirstName}#{self.LastName}".sum % available.count
      Rails.logger.debug "Client#image id:#{self.id} faked #{self.PersonalID} #{available.count} #{available[image_id]}" # rubocop:disable Style/RedundantSelf
      image_data = File.read(available[image_id]) # rubocop:disable Lint/UselessAssignment
    end

    def set_local_client_image_cache(image_data) # rubocop:disable Naming/AccessorMethodName
      return unless image_data.present?

      user = ::User.setup_system_user
      self.class.transaction do
        client_files.window.where(name: 'Client Headshot Cache')&.delete_all
        file = GrdaWarehouse::ClientFile.create(
          client_id: id,
          user_id: user.id,
          name: 'Client Headshot Cache',
          visible_in_window: true,
        )
        file.client_file.attach(io: StringIO.open(image_data), filename: "client_headshot_cache_#{id}")
        file.save!
      end
    end

    private def uploaded_local_image
      client_files.window.tagged_with('Client Headshot').order(updated_at: :desc).limit(1)&.first
    end

    private def local_client_image_cache
      client_files.window.where(name: 'Client Headshot Cache').where(updated_at: 1.days.ago..DateTime.tomorrow).limit(1)&.first
    end
  end
end
