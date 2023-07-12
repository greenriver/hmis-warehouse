###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::EsgFundingService < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    description 'AC ESG Funding Service'

    field :id, ID, null: false
    field :client_id, ID, null: false
    field :client_dob, GraphQL::Types::ISO8601Date, null: true
    field :mci_ids, [Types::HmisSchema::ExternalIdentifier], null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :project_id, ID, null: false
    field :project_name, String, null: false
    field :organization_id, ID, null: false
    field :organization_name, String, null: false
    field :date_provided, GraphQL::Types::ISO8601Date, null: false
    field :fa_amount, Float, null: true
    field :fa_start_date, GraphQL::Types::ISO8601Date, null: true
    field :fa_end_date, GraphQL::Types::ISO8601Date, null: true

    custom_data_elements_field

    def custom_data_elements
      definition_scope = Hmis::Hud::CustomDataElementDefinition.
        for_type(object.class.name).
        for_service_type(object.custom_service_type_id)

      resolve_custom_data_elements(object, definition_scope: definition_scope)
    end

    def project_id
      object.project.project_id
    end

    def project_name
      object.project.project_name
    end

    def organization_id
      object.project.organization.organization_id
    end

    def organization_name
      object.project.organization.organization_name
    end

    def client_id
      object.client.id
    end

    def client_dob
      object.client.dob
    end

    def first_name
      object.client.first_name
    end

    def last_name
      object.client.last_name
    end

    def mci_ids
      object.client.external_identifiers.select { |identifier| identifier[:type] == :mci_id }
    end
  end
end
