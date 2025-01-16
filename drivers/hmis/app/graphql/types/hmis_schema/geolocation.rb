###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Geolocation < Types::BaseObject
    field :id, ID, null: false
    field :coordinates, HmisSchema::GeolocationCoordinates, null: false
    field :project_name, String, null: true, method: :collected_by, description: 'Name of the Project that collected the location'
    field :collected_by, Application::User, null: true, description: 'User who collected the location'
    field :located_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'Timestamp when the location was collected'
    field :source_form_name, String, null: true, description: 'Name of the form that collected this location'

    # backed by ClientLocationHistory::Location

    def located_at
      # We should have `located_at` if this location was processed from an HMIS form or HMIS External form,
      # but use created_at as a backup since it's required.
      object.located_at || object.created_at
    end

    # coordinates need to be nested under another object because form processing uses 'Geolocation.coordinates',
    # so we need to resolve it that way for populating forms
    def coordinates
      object
    end

    def source_form_name
      return unless form_processor

      case form_processor.owner_type
      when Hmis::Hud::CurrentLivingSituation.sti_name
        'Current Living Situation'
      when Hmis::Hud::CustomAssessment.sti_name
        load_ar_association(form_processor, :definition)&.title || 'Assessment'
      when HmisExternalApis::ExternalForms::FormSubmission.sti_name
        load_ar_association(form_processor, :definition)&.title || 'External Form'
      end
    end

    # User who collected the location. We don't actually have this, so we just look at who created
    # the form that collected the location. This could be wrong if the location was added later by someone else.
    # It would be better to add a column to clh_locations to store the user who collected the location.
    def collected_by
      return unless form_processor

      load_created_by_user_from_versions(form_processor)
    end

    private

    def form_processor
      load_ar_association(object, :form_processor)
    end
  end
end
