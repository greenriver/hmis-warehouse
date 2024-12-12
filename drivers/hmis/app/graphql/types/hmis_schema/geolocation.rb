###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Geolocation < Types::BaseObject
    field :id, ID, null: false
    field :coordinates, HmisSchema::GeolocationCoordinates, null: true
    field :collected_by_project_name, String, null: true, method: :collected_by
    field :located_on, GraphQL::Types::ISO8601Date, null: true, description: 'Date the location was collected, usually sourced from Assessment Date or Information Date of the form where it was collected'
    field :source_current_living_situation, HmisSchema::CurrentLivingSituation, null: true, description: 'Associated Current Living Situation record, if this location was collected on a CurrentLivingSituation form'
    field :source_assessment, HmisSchema::Assessment, null: true, description: 'Associated Assessment record, if this location was collected on an assessment'

    # Not needed currently, but may want some of these later
    # field :located_at, GraphQL::Types::ISO8601DateTime, null: true
    # field :processed_at, GraphQL::Types::ISO8601DateTime, null: true
    # field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    # field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # backed by ClientLocationHistory::Location

    def located_on
      # We should have `located_on` if this location was processed from an HMIS form or HMIS External form.
      # All these date fields are optional, though, so coalesce (and use created_at if all are nil).
      [object.located_on, object.located_at.to_date, object.processed_at.to_date, object.created_at.to_date].compact.first
    end

    # coordinates need to be nested under another object because form processing uses 'Geolocation.coordinates',
    # so we need to resolve it that way for populating forms
    def coordinates
      object
    end

    def source_assessment
      form_processor_owner if form_processor_owner.is_a?(Hmis::Hud::CustomAssessment)
    end

    def source_current_living_situation
      form_processor_owner if form_processor_owner.is_a?(Hmis::Hud::CurrentLivingSituation)
    end

    private

    def form_processor_owner
      object.form_processor&.owner
    end
  end
end
