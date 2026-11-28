###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-time grant, run from a data migration. Each existing cohort's participants who
# hold can_configure_cohorts through a non-system role become that cohort's managers,
# so they keep the configure access they had before it became per-cohort.
# Cohorts that already have a manager group (even an empty one) are left alone, so a
# manager an admin has since removed is not re-added.
module GrdaWarehouse::Tasks
  class BackfillCohortManagers
    # @return [Hash] counts of cohorts granted managers and cohorts skipped for having a manager group
    def run!
      managed_cohort_ids = UserGroup.system.where(source_type: GrdaWarehouse::Cohort.sti_name, context: :manager).pluck(:source_id)
      counts = { granted: 0, skipped_existing: 0 }
      counts[:skipped_existing] = GrdaWarehouse::Cohort.where(system_cohort: false, id: managed_cohort_ids).count

      PaperTrail.request(whodunnit: User.system_user.id.to_s) do
        GrdaWarehouse::Cohort.where(system_cohort: false).where.not(id: managed_cohort_ids).find_each do |cohort|
          managers = eligible_users(cohort)
          next if managers.empty?

          # Outside a migration each cohort rolls back on its own; inside one, the migration's
          # transaction makes the whole run atomic. The manager group is the done marker either way.
          ApplicationRecord.transaction { cohort.replace_access(managers, scope: :manager) }
          counts[:granted] += 1
        end
      end
      User.clear_cached_permissions
      counts
    end

    private def eligible_users(cohort)
      participants = UserGroup.system.find_by(source: cohort, context: :editable)&.users
      return [] unless participants

      configurers = User.where(id: User.joins(:roles).merge(Role.not_system).where(roles: { can_configure_cohorts: true }).select(:id))
      participants.active.merge(configurers).select(&:using_acls?)
    end
  end
end
