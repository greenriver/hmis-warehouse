###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralSourceHouseholdMember < Types::BaseObject
    # object is a Hmis::Hud::Enrollment belonging to the household that is the "source" of a CE Referral
    # NOTE: this type can be resolved even if the current user does not have full enrollment details access.

    field :id, ID, null: false
    field :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, null: false
    field :client_name, String, null: false, description: 'The name of the client. Returns masked name if the user does not have permission to view the client name.'

    # Access field informs whether the frontend can display a link to the Client profile for this household member.
    # Use plural "can view clients" to match the permission name resolved elsewhere in application
    access_field do
      field :can_view_clients, Boolean, null: false
    end

    def client_name
      client = load_ar_association(object, :client)
      if can_view_client && current_permission?(permission: :can_view_client_name, entity: client)
        client.brief_name
      else
        client.masked_name
      end
    end

    def access
      { can_view_clients: can_view_client }
    end

    private

    def can_view_client
      current_permission?(permission: :can_view_clients, entity: client)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
