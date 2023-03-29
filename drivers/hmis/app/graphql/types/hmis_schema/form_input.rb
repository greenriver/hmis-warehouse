###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::FormInput < Types::BaseInputObject
    # Form definition used
    argument :form_definition_id, ID, required: true
    # Record being updated (if update)
    argument :record_id, ID, required: false
    # Needed for Service creation
    argument :enrollment_id, ID, required: false
    # Needed for Project creation
    argument :organization_id, ID, required: false
    # Needed for File creation
    argument :client_id, ID, required: false
    # Needed for Funder/ProjectCoC/etc creation
    argument :project_id, ID, required: false
    # Raw form state as JSON
    argument :values, Types::JsonObject, required: false
    # Transformed HUD values as JSON
    argument :hud_values, Types::JsonObject, required: false
    # Whether warnings have been confirmed
    argument :confirmed, Boolean, required: false
  end
end
