###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Copyright 2016 - 2025 Green River Data Analysis, LLC
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

    def relation_name
      :clh_location
    end

    def process(field, value)
      attribute_name = ar_attribute_name(field)
      # The only expected attribute name is 'coordinates'
      raise ArgumentError, "Unexpected attribute for Geolocation: #{attribute_name}" unless attribute_name == 'coordinates'

      # if 'Geolocation.coordinates: nil' was submitted, destroy the clh location record
      return destroy_record unless value.present?

      attribute_value = clean_coordinate_value(value).compact_blank
      latitude = attribute_value[:latitude]
      longitude = attribute_value[:longitude]
      not_collected_reason = attribute_value[:notCollectedReason]

      return destroy_record if not_collected_reason # not collected reason is returned from external PIT form
      return destroy_record unless latitude && longitude

      @processor.send(factory_name).assign_attributes(lat: latitude, lon: longitude)
    end

    def clean_coordinate_value(value)
      if value.is_a?(String)
        JSON.parse(value, symbolize_names: true)
      elsif value.is_a?(Hash)
        value.symbolize_keys
      else
        raise ArgumentError, 'Geolocation coordinates in unexpected format'
      end
    end

    def assign_metadata
      clh = @processor.send(factory_name, create: false)
      return unless clh
      return if clh.marked_for_destruction?

      processed_at = Time.current

      owner = @processor.owner_factory

      # If Latitude or Longitude have changed (or are new), set attributes about location context.
      if clh.lat_changed? || clh.lon_changed?
        located_on, located_at = case owner
        when HmisExternalApis::ExternalForms::FormSubmission
          [owner.submitted_at.to_date, owner.submitted_at]
        when Hmis::Hud::CurrentLivingSituation
          [owner.InformationDate, processed_at]
        when Hmis::Hud::CustomAssessment
          # Use processing time (now) for located_at time. This could be wrong
          # if the location was recorded and then the assessment was saved as WIP for a while before submission.
          # However there's no way for us to know that, so just use the processing time.
          [owner.AssessmentDate, processed_at]
        else
          raise "owner type not supported for geolocation collection: #{owner.class}"
        end

        clh.located_on = located_on # Date
        clh.located_at = located_at # DateTime (newer, added for HMIS)
        clh.processed_at = processed_at
      end

      clh.assign_attributes(
        source: @processor.enrollment_factory,
        collected_by: @processor.enrollment_factory.project.name,
      )
    end

    def information_date(_)
    end

    # This record type can be conditionally collected on CustomAssessments/CLS
    def dependent_destroyable?
      true
    end
  end
end
