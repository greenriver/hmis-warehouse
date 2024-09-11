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

    def assign_metadata
      clh = @processor.send(factory_name, create: false)
      return if clh&.destroyed?

      clh&.assign_attributes(
        source: @processor.enrollment_factory,
        # TODO(#5726) For PIT, entry_date holds the submission time of the form, but that won't be true for CLS
        # or other geolocation collection. One idea is to update this to onl yset located_on from the enrollment
        # as a fallback, but receive it from the form otherwise: {record_type:GEOLOCATION, field_name: located_on}
        located_on: @processor.enrollment_factory.entry_date,
        processed_at: Time.current,
        collected_by: @processor.enrollment_factory.project.name,
      )
    end
  end
end
