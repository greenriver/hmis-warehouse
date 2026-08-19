###
# Copyright Green River Data Group, Inc.
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

    def project_id
      object.project.project_id
    end

    def project_name
      project.project_name
    end

    def organization_id
      organization.organization_id
    end

    def organization_name
      organization.organization_name
    end

    def client_id
      client.id
    end

    def client_dob
      client.dob if client_policy.can_view_dob?
    end

    def first_name
      client_policy.can_view_name? ? client.first_name : client.masked_name
    end

    def last_name
      client.last_name if client_policy.can_view_name?
    end

    def mci_ids
      collection = Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: client,
        ac_hmis_mci_ids: load_ar_association(client, :ac_hmis_mci_ids),
      )
      collection.mci_identifiers
    end

    protected

    def client
      load_ar_client_association(object)
    end

    # Name and DOB follow the same rules as the Client type, so restricted clients are redacted here too
    def client_policy
      @client_policy ||= policy_for(client, policy_type: :hmis_client)
    end

    def project
      load_ar_association(object, :project)
    end

    def organization
      load_ar_association(project, :organization)
    end
  end
end
