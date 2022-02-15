###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory::GrdaWarehouse
  module HmisFormExtension
    extend ActiveSupport::Concern

    included do
      has_many :client_locations, class_name: 'ClientLocationHistory::Location', as: :source

      scope :with_location_data, -> do
        joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.with_location_data)
      end

      def self.cleanup_missing_locations
        ClientLocationHistory::Location.where(source_type: 'GrdaWarehouse::HmisForm').
          where.not(source_id: with_location_data.select(:id)).delete_all
      end

      def self.maintain_location_histories
        ids = with_location_data.oldest_first.
          where(
            arel_table[:location_processed_at].eq(nil).
            or(arel_table[:collected_at].gt(arel_table[:location_processed_at])),
          ).pluck(:id)
        return unless ids

        # Remove any locations where the hmis_form no longer exists
        cleanup_missing_locations

        # loop over those records in batches of 100
        ids.each_slice(100) do |batch|
          with_location_data.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
            next unless hmis_form.destination_client.present?

            lat = hmis_form.lat
            # mark this form as processed so we don't try again unless it changes
            hmis_form.update(location_processed_at: Time.current)
            next unless lat

            location = hmis_form.client_locations.first_or_initialize
            location.update(
              client_id: hmis_form.destination_client.id,
              collected_by: hmis_form.collection_location,
              located_on: hmis_form.collected_at,
              lat: lat,
              lon: hmis_form.lon,
              processed_at: Time.current,
            )
          end
        end
      end

      private def lat_lon
        relevant_section = answers[:sections].select do |section|
          section[:section_title].downcase.include?('contact') && section[:questions].present?
        end&.first
        return nil unless relevant_section.present?

        relevant_question = relevant_section[:questions].select do |question|
          question[:question].downcase.include?('gis coordinates')
        end&.first.try(:[], :answer)
        relevant_question
      end

      def lat
        lat_lon&.split(/, ?/)&.first
      end

      def lon
        lat_lon&.split(/, ?/)&.last
      end
    end
  end
end
