###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralSourceHouseholdMember < Types::BaseObject
    # object is a Hmis::Hud::Enrollment belonging to the household that is the "source" of a CE Referral
    # NOTE: this type can be resolved even if the current user does not have full enrollment details access.

    field :id, ID, null: false # enrollment id
    field :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, null: false
    field :client_id, ID, null: false
    field :client_name, String, null: false, description: 'The name of the client. Returns masked name if the user does not have permission to view the client name.'

    # Access field informs whether the frontend can display a link to the Client profile for this household member.
    # Use plural "can view clients" to match the permission name resolved elsewhere in application
    access_field do
      field :can_view_clients, Boolean, null: false
    end

    def client_id
      client.id
    end

    def client_name
      return client.masked_name unless policy.can_view? && policy.can_view_name?

      client.brief_name
    end

    def access
      { can_view_clients: policy.can_view? }
    end

    private

    def policy
      @policy ||= policy_for(client, policy_type: :hmis_client)
    end

    def client
      load_ar_client_association(object)
    end
  end
end
