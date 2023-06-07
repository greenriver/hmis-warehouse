###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPosting < Types::BaseObject
    description 'A referral for a household of one or more clients'

    field :id, ID, null: false

    # Fields that come from Referral
    field :referral_identifier, ID
    field :referral_date, GraphQL::Types::ISO8601Date, null: false
    field :referred_by, String, null: false
    field :referral_notes, String
    field :chronic, Boolean
    field :score, Integer
    field :needs_wheelchair_accessible_unit, Boolean

    # Fields that come from ReferralHouseholdMembers
    field :hoh_name, String, null: false
    field :household_size, Integer, null: false
    field :household_members, [HmisSchema::ReferralHouseholdMember], null: false

    # Fields that come from Posting
    field :resource_coordinator_notes, String
    field :posting_identifier, ID, method: :identifier
    field :assigned_date, GraphQL::Types::ISO8601Date, null: false, method: :created_at
    field :referral_request, HmisSchema::ReferralRequest
    field :status, HmisSchema::Enums::ReferralPostingStatus, null: false
    field :status_updated_at, GraphQL::Types::ISO8601Date
    field :status_updated_by, String
    field :status_note, String
    field :status_note_updated_at, GraphQL::Types::ISO8601Date
    field :status_note_updated_by, String
    field :denial_reason, String
    field :referral_result, HmisSchema::Enums::Hud::ReferralResult
    field :denial_note, String
    field :referred_from, String, null: false
    field :unit_type, HmisSchema::UnitTypeObject, null: false

    # If this posting has been accepted, this is the enrollment for the HoH at the enrolled household.
    # This enrollment is NOT necessarily the same as the `hoh_name`, because the HoH may have changed after
    # posting was accepted.
    field :hoh_enrollment, HmisSchema::Enrollment, null: true

    def hoh_name
      object.referral.household_members
        .detect(&:self_head_of_household?)
        &.client&.brief_name
    end

    def hoh_enrollment
      return unless object.household_id

      Hmis::Hud::Enrollment.viewable_by(current_user).
        where(household_id: object.household_id).
        heads_of_households.first
    end

    def household_members
      object.referral.household_members
    end

    def household_size
      object.referral.household_members.size
    end

    def referred_from
      object.project&.project_name || 'Coordinated Entry'
    end

    def status
      object.status
    end

    def status_updated_by
      object.status_updated_by&.email
    end

    def status_note_updated_by
      object.status_note_updated_by&.email
    end

    def referral_identifier
      object.referral.identifier
    end

    def referred_by
      object.referral.service_coordinator
    end

    [:referral_date, :referral_notes, :chronic, :score, :needs_wheelchair_accessible_unit].each do |name|
      define_method(name) do
        object.referral.send(name)
      end
    end
  end
end
