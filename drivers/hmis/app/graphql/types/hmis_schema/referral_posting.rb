###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralPosting < Types::BaseObject
    description 'A referral for a household of one or more clients'

    include Types::HmisSchema::HasCustomDataElements

    field :id, ID, null: false

    # Fields that come from Referral
    field :referral_identifier, ID
    field :referral_date, GraphQL::Types::ISO8601DateTime, null: false
    field :referred_by, String, null: false
    field :referral_notes, String
    field :chronic, Boolean
    field :hud_chronic, Boolean
    field :score, Integer
    field :needs_wheelchair_accessible_unit, Boolean

    # Fields that come from ReferralHouseholdMembers
    field :hoh_name, String, null: false
    field :hoh_mci_id, ID, null: true
    field :hoh_client, HmisSchema::Client, null: true
    field :household_size, Integer, null: false
    field :household_members, [HmisSchema::ReferralHouseholdMember], null: false

    # Fields that come from Posting
    field :resource_coordinator_notes, String
    field :posting_identifier, ID, method: :identifier
    field :assigned_date, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :referral_request, HmisSchema::ReferralRequest
    field :status, HmisSchema::Enums::ReferralPostingStatus, null: false
    field :status_updated_at, GraphQL::Types::ISO8601DateTime
    field :status_updated_by, String
    field :status_note, String
    field :status_note_updated_at, GraphQL::Types::ISO8601DateTime
    field :status_note_updated_by, String
    field :denial_reason, HmisSchema::Enums::ReferralPostingDenialReasonType
    field :referral_result, HmisSchema::Enums::Hud::ReferralResult
    field :denial_note, String
    field :referred_from, String, null: false, description: 'Name of project or external source that the referral originated from'
    field :unit_type, HmisSchema::UnitTypeObject, null: true
    field :project, HmisSchema::Project, null: true, description: 'Project that household is being referred to'
    field :organization, HmisSchema::Organization, null: true
    custom_data_elements_field

    # If this posting has been accepted, this is the enrollment for the HoH at the enrolled household.
    # This enrollment is NOT necessarily the same as the `hoh_name`, because the HoH may have changed after
    # posting was accepted.
    field :hoh_enrollment, HmisSchema::Enrollment, null: true, description: 'Enrollment for the HoH at the receiving Project (if the referral was accepted)'

    # Decided not to add this yet, but leaving comment in case there is a request in the future to link them up.
    # field :source_enrollment, HmisSchema::Enrollment, null: true, description: 'Source Enrollment in the Project that generated the referral (if any)'

    def referral_result
      object.referral_result_before_type_cast
    end

    def hoh_member
      household_members.detect(&:self_head_of_household?)
    end

    def hoh_name
      hoh_member&.client&.brief_name
    end

    def hoh_mci_id
      hoh_member&.mci_id
    end

    def hoh_client
      hoh_enrollment&.client
    end

    def hoh_enrollment
      return unless object.household_id.present?

      load_ar_association(object, :hoh_enrollment)
    end

    def household_members
      load_ar_association(referral, :household_members)
    end

    def household_size
      household_members.map(&:client_id).uniq.size
    end

    def hud_chronic
      # HUD Chronic status for the client that was referred as HoH
      referred_hoh_client = hoh_member&.client
      return unless referred_hoh_client.present?

      # Users can see HUD Chronic status for clients being referred to their program, even if the client isn't enrolled yet.
      # That's why the "entity" is project and not client.
      return unless current_permission?(permission: :can_view_hud_chronic_status, entity: project)

      # client.hud_chronic causes n+1 queries, only use when resolving 1 posting
      !!referred_hoh_client.hud_chronic?(scope: referred_hoh_client.enrollments)
    end

    def referred_from
      enrollment_project&.project_name || 'Coordinated Entry'
    end

    def organization
      project&.organization
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
      referral.identifier
    end

    def referred_by
      referral.service_coordinator
    end

    def unit_type
      load_ar_association(referral, :unit_type)
    end

    [:referral_date, :referral_notes, :chronic, :score, :needs_wheelchair_accessible_unit].each do |name|
      define_method(name) do
        referral.send(name)
      end
    end

    def project
      load_ar_association(object, :project)
    end

    def referral
      load_ar_association(object, :referral)
    end

    # Decided not to add this yet, but leaving comment in case there is a request in the future to link them up.
    # def source_enrollment
    #   return unless current_permission?(permission: :can_view_project, entity: enrollment_project)
    #   return unless current_permission?(permission: :can_view_enrollment_details, entity: enrollment_project)

    #   protected_source_enrollment
    # end

    protected

    # Note: The User who can view this referral may not have access to view the referring project.
    def protected_source_enrollment
      load_ar_association(referral, :enrollment)
    end

    # Note: The User who can view this referral may not have access to view the referring project.
    def enrollment_project
      return unless protected_source_enrollment.present?

      load_ar_association(protected_source_enrollment, :project)
    end
  end
end
