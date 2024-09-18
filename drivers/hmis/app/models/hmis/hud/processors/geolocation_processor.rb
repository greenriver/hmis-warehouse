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
      return if value.nil? || value.empty?

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

      owner = @processor.owner_factory
      located_on, located_at = case owner
      when HmisExternalApis::ExternalForms::FormSubmission
        [owner.submitted_at.to_date, owner.submitted_at]
      when Hmis::Hud::CurrentLivingSituation
        [nil, owner.InformationDate]
      when Hmis::Hud::CustomAssessment
        [nil, owner.AssessmentDate]
      else
        raise 'unable to determine located_on date for client location'
      end

      clh&.assign_attributes(
        source: @processor.enrollment_factory,
        collected_by: @processor.enrollment_factory.project.name,
        located_on: located_on,
        located_at: located_at,
        processed_at: Time.current,
      )
    end
  end
end
