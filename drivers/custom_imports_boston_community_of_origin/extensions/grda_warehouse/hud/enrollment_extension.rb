###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin::GrdaWarehouse::Hud
  module EnrollmentExtension
    extend ActiveSupport::Concern

    included do
      has_one :client_location, class_name: 'ClientLocationHistory::Location', as: :source

      scope :with_location_data, -> do
        where.not(LastPermanentZIP: nil)
      end

      def self.maintain_location_histories
        # Remove orphaned locations
        ClientLocationHistory::Location.where(source_type: 'GrdaWarehouse::Hud::Enrollment').
          where.not(source_id: with_location_data.select(:id)).delete_all

        # LastPermanentZIP is only required for VA enrollments, and may be removed in the future,
        # so we are finding zips that we don't already have, but not tracking changes to enrollments
        # afterwards.

        # Add new locations
        new_enrollment_ids = where.not(
          id: ClientLocationHistory::Location.where(source_type: 'GrdaWarehouse::Hud::Enrollment').
            select(:source_id),
        ).pluck(:id)
        cached_zips = {} # Number of zips is bounded, store location data for them to avoid repeated queries
        # :client_location, is included to avoid an N+1 in build_client_location
        where(id: new_enrollment_ids).includes(:client_location, project: :organization, client: :destination_client).find_in_batches do |batch|
          locations = []
          batch.each do |enrollment|
            next unless enrollment.client.destination_client.present?

            zip = enrollment.LastPermanentZIP
            place = cached_zips[zip] ||= Nominatim.search.country('us').postalcode(zip).first
            next unless place # Nominatim didn't return anything

            lat = place.lat
            lon = place.lon
            locations << enrollment.build_client_location(
              client_id: enrollment.client.destination_client.id,
              located_on: enrollment.EntryDate,
              lat: lat,
              lon: lon,
              collected_by: enrollment&.project&.name,
            )
          end
          puts locations.size
        ensure # Aways save any locations that we got
          ClientLocationHistory::Location.import!(locations)
        end
      rescue Faraday::ConnectionFailed
        # We have overheated the API, so, give up
      end
    end
  end
end
