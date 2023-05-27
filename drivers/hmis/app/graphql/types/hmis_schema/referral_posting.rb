###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPosting < Types::BaseObject
    field :id, ID, null: false

    # Fields that come from Referral
    field :referral_identifier, ID, null: true
    field :referral_date, GraphQL::Types::ISO8601Date, null: false
    field :referred_by, String, null: false # service coordinator
    field :referral_notes, String, null: true
    field :resource_coordinator_notes, String, null: true
    field :chronic, Boolean, null: true
    field :score, Integer, null: true
    field :needs_wheelchair_accessible_unit, Boolean, null: true

    # Fields that come from ReferralHouseholdMembers
    # hoh_name    // client.brief_name for the client where the relationship_to_hoh is 1
    # householdSize
    # clients {  Client type }

    # Fields that come from Posting
    # postingIdentifier
    # assignedDate // date created on the posting
    # referralRequest { ReferralRequest type }
    # status   // probably the updated_at and updated_by too
    # statusNote   // probably the updated_at and updated_by too
    # denialReason
    # referralResult
    # denialNote

    # Computed fields
    #
    # If  there is an enrollment linked to the Referral, this should be the `.project.project_name` of that enrollment.
    # If not, it should just be "Coordinated Entry"
    # referredFrom
  end
end
