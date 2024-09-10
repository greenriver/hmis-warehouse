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

      if attribute_name == 'coordinates'
        attribute_value = JSON.parse(value, symbolize_names: true)
        latitude = attribute_value[:latitude]
        longitude = attribute_value[:longitude]
        not_collected_reason = attribute_value[:notCollectedReason]
        raise ArgumentError, 'Geolocation coordinates in unexpected format' unless (latitude && longitude) || not_collected_reason

        return @processor.send(factory_name).destroy if not_collected_reason

        @processor.send(factory_name).assign_attributes(lat: latitude, lon: longitude)
      else
        @processor.send(factory_name).assign_attributes(attribute_name => value)
      end
    end

    def assign_metadata
      clh = @processor.send(factory_name, create: false)
      return if clh&.destroyed?

      clh&.assign_attributes(
        source: @processor.enrollment_factory,
        located_on: @processor.enrollment_factory.entry_date, # entry_date holds the submission time of the form
        processed_at: Time.now,
        collected_by: @processor.enrollment_factory.project.name,
      )
    end
  end
end
