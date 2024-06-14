###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientImageConsumer
  extend ActiveSupport::Concern
  included do
    has_many :client_files unless respond_to?(:client_files)
    has_many :source_eto_client_lookups, through: :source_clients, source: :eto_client_lookups

    # Returns actual image bytes. Cache time limit not yet implemented.
    def image(_cache_for = 10.minutes)
      # Check first for locally uploaded image or a cached ETO image
      # Otherwise, check for an image connected to the source client
      local_client_image_data || source_clients.detect(&:image_for_source_client)&.image_for_source_client
    end

    def image_for_source_client(_cache_for = 10.minutes)
      return '' unless headshot_visible? && source?

      # Check for HMIS uploaded images
      image_data = local_hmis_image&.as_thumb

      # Return fake image if no image is on file and it's non-prod
      return image_data || fake_client_image_data || self.class.no_image_on_file_image unless Rails.env.production?

      # In prod only, check the ETO API. This caches its results in the client_files db
      image_data || eto_source_image_data || self.class.no_image_on_file_image
    end

    def local_client_image_data
      # If there's an uploaded file in the warehouse, return it
      headshot = uploaded_local_image
      return headshot.as_thumb if headshot

      # Otherwise, return any other client image (such as locally cached ETO)
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

    def headshot_visible?
      GrdaWarehouse::Config.get(:eto_api_available) || HmisEnforcement.hmis_enabled?
    end

    def self.no_image_on_file_image
      return File.read(Rails.root.join('public', 'no_photo_on_file.jpg'))
    end

    def eto_source_image_data
      return '' unless GrdaWarehouse::Config.get(:eto_api_available)

      api_configs = EtoApi::Base.api_configs
      image_data = nil
      eto_client_lookups.detect do |c_lookup|
        api_key = api_configs.select { |_k, v| v['data_source_id'] == c_lookup.data_source_id }&.keys&.first
        return '' unless api_key.present?

        api ||= EtoApi::Base.new(api_connection: api_key).tap(&:connect)
        image_data = api.client_image( # rubocop:disable Style/RescueModifier
          client_id: c_lookup.participant_site_identifier,
          site_id: c_lookup.site_id,
        ) rescue nil
        image_data&.length&.positive?
      end
      return '' unless image_data.present?

      set_local_client_image_cache(image_data)
      image_data
    end

    # Caches images on the source client
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
      # These need to be flagged as available in the Window. Since we cache these
      # in the file-system, we'll only show those that would be available to people
      # with window access.
      # Only works on the destination client
      client_files.window.tagged_with('Client Headshot').order(updated_at: :desc).limit(1)&.first
    end

    def local_hmis_image
      # Doesn't check for the window flag since these are uploaded from OP HMIS
      # Works on source clients
      return '' unless source?

      client_files.tagged_with('Client Headshot').order(updated_at: :desc).limit(1)&.first
    end

    private def local_client_image_cache
      # These need to be flagged as available in the Window. Since we cache these
      # in the file-system, we'll only show those that would be available to people
      # with window access
      client_files.window.where(name: 'Client Headshot Cache').where(updated_at: 1.days.ago..DateTime.tomorrow).limit(1)&.first
    end
  end
end
