#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Hmis::Hud::Processors
  class GeolocationProcessor < Base
    def factory_name
      # todo @martha - rename this
      :clh_location_factory
    end

    def schema
      # todo @martha - test this
      nil
    end

    def process(field, value)
      attribute_name = ar_attribute_name(field)

      if attribute_name == 'coordinates'
        attribute_value = JSON.parse(value, symbolize_names: true)
        latitude = attribute_value[:latitude]
        longitude = attribute_value[:longitude]
        raise unless latitude && longitude

        @processor.send(factory_name).assign_attributes(lat: latitude, lon: longitude)
      else
        @processor.send(factory_name).assign_attributes(attribute_name => value)
      end
    end

    def assign_metadata
      @processor.send(factory_name, create: false)&.assign_attributes(
        source: @processor.enrollment_factory,
        located_on: @processor.enrollment_factory.entry_date, # todo @martha - get the submission date. should be enrollment entry. comment about why
        processed_at: Time.now,
        collected_by: @processor.enrollment_factory.project.name,
      )
    end
  end
end
