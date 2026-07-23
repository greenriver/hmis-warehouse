###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidatePoolSummary < Types::BaseObject
    skip_activity_log

    field :total_count, Integer, null: false, description: 'Number of active CE candidate pools'
    field :never_fully_generated_count, Integer, null: false, description: 'Active pools that have never completed a full generation'

    def total_count
      scoped_active_pools.count
    end

    def never_fully_generated_count
      scoped_active_pools.where(candidates_fully_generated_at: nil).count
    end

    private

    def scoped_active_pools
      @scoped_active_pools ||= begin
        scope = Hmis::Ce::Match::CandidatePool.active.in_data_source(current_user.hmis_data_source_id)

        # Filter to CandidatePools used by the project group, if provided
        project_group_id = object[:project_group_id]
        scope = scope.in_project_group(project_group_id) if project_group_id.present?

        scope
      end
    end
  end
end
