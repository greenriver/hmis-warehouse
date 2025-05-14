###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Unit < Types::BaseObject
    available_filter_options do
      arg :unit_type, [ID]
      arg :status, [
        Types::BaseEnum.generate_enum('UnitFilterOptionStatus') do
          # FIXME standardize names "Assigned/Empty"
          value 'AVAILABLE', description: 'Available'
          value 'FILLED', description: 'Filled'
        end,
      ]
    end

    field :id, ID, null: false
    field :name, String, null: false
    # Not resolving start/end dates because we only resolve active units (for now)
    # field :start_date, GraphQL::Types::ISO8601Date, null: false
    # field :end_date, GraphQL::Types::ISO8601Date, null: true
    field :unit_type, Types::HmisSchema::UnitTypeObject, null: true
    field :project, Types::HmisSchema::Project, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :occupants, [HmisSchema::Enrollment], null: false
    field :user, Application::User, null: true
    field :unit_size, Integer, null: true
    field :latest_opportunity, HmisSchema::CeOpportunity, null: true, description: "The unit's most recent opportunity, which could be currently active or already closed"
    field :accepting_ce_referrals, Boolean, null: false

    def user
      user = load_ar_association(object, :user)
      return unless user.present?

      user.hmis_data_source_id = current_user.hmis_data_source_id
      Hmis::Hud::User.from_user(user)
    end

    def unit_size
      return object.unit_size if object.unit_size.present?

      object.unit_type&.unit_size
    end

    def occupants
      load_ar_association(object, :current_occupants)
    end

    def unit_type
      load_ar_association(object, :unit_type)
    end

    def name
      Hmis::Unit.display_name(id: object.id, name: object.name, unit_type: unit_type)
    end

    def latest_opportunity
      # No additional permission check. If the user can view this unit, they can view the opportunity
      load_ar_association(object, :latest_opportunity)
    end

    def accepting_ce_referrals
      # No additional permission check. If the user can view this unit, they can view the opportunity.
      # They may _not_ be able to view the referral; but the referral object is not actually resolved here,
      # just used to determine whether the unit is currently accepting referrals.

      # First check for an existing opportunity. If there is none, or it's already closed, then this unit isn't accepting referrals
      latest_opportunity = load_ar_association(object, :latest_opportunity)
      return false if latest_opportunity.nil? || latest_opportunity.closed?

      # Otherwise, the unit is only accepting referrals if the opportunity doesn't already have an active referral.
      # (The opportunity is open, so it shouldn't have an accepted referral. Possible referral statuses are either active or rejected.)
      load_ar_association(object, :active_referral).nil?
    end
  end
end
