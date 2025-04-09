###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::MarkUnitsUnavailable < CleanBaseMutation
    argument :unit_ids, [ID], required: true
    field :units, [Types::HmisSchema::Unit], null: false

    def resolve(unit_ids:)
      raise unless Hmis::Ce.configuration.enabled?

      units = Hmis::Unit.preload(:current_occupants).where(id: unit_ids)

      project_ids = units.pluck(:project_id).uniq
      raise 'Cannot manage units across projects' if project_ids.size > 1

      project = Hmis::Hud::Project.find_by(id: project_ids.first)
      raise 'Access denied' unless current_user.permissions_for?(project, :can_manage_units)

      opportunities = Hmis::Ce::Opportunity.active.
        where(owner_type: 'Hmis::Unit', owner_id: unit_ids).
        preload(:active_referral)

      raise 'Not found' unless opportunities.any?
      raise 'Cannot mark opportunity unavailable if it has an active referral' if opportunities.any?(&:active_referral)

      # Already validated that the opportunities don't have active referrals, so use delete_all instead of destroy_all to avoid n+1
      opportunities.delete_all

      { units: Hmis::Unit.where(id: unit_ids) }
    end
  end
end
