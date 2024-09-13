#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Hmis::Hud::Processors
  class GeolocationProcessor < Base
    def factory_name
      :clh_location_factory
    end

    def schema
      nil
    end

    def process(field, value)
      attribute_name = ar_attribute_name(field)

      raise ArgumentError, "Unexpected attribute for Geolocation: #{attribute_name}" unless attribute_name == 'coordinates'

      attribute_value = JSON.parse(value, symbolize_names: true)
      latitude = attribute_value[:latitude]
      longitude = attribute_value[:longitude]
      not_collected_reason = attribute_value[:notCollectedReason]

      raise ArgumentError, 'Geolocation coordinates in unexpected format' unless (latitude && longitude) || not_collected_reason

      return @processor.send(factory_name).destroy if not_collected_reason

      @processor.send(factory_name).assign_attributes(lat: latitude, lon: longitude)
    end

    def information_date(date)
      # TODO(#5726) This logic may need to be updated for CLS.
      # Maybe unintuitive, but for PIT, we store the timestamp of the form submission in the processed_at field because
      # it is a granular timestamp and not a date like located_on.
      @processor.send(factory_name, create: false)&.assign_attributes(processed_at: date, located_on: date)
    end

    def assign_metadata
      clh = @processor.send(factory_name, create: false)
      return if clh&.destroyed?

      clh&.assign_attributes(
        source: @processor.enrollment_factory,
        collected_by: @processor.enrollment_factory.project.name,
      )
    end
  end
end
