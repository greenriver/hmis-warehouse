class MigrateExistingCohortPermissions < ActiveRecord::Migration[6.1]
  def up
    r_t = Role.arel_table
    # Add users with all cohorts permissions to all cohorts group
    roles = Role.where(
      r_t[:can_manage_cohorts].eq(true).
        or(r_t[:can_edit_cohort_clients].eq(true)),
    )
    users = roles.map(&:users).flatten
    all_cohorts_group = AccessGroup.find_by(name: 'All Cohorts')
    all_cohorts_group.add(users)

    Role.where(can_manage_cohorts: true).update_all(
        can_configure_cohorts: true,
        can_add_cohort_clients: true,
        can_manage_cohort_data: true,
        can_manage_inactive_cohort_clients: true,
        can_view_cohort_client_changes_report: true,
    )

    Role.where(can_edit_cohort_clients: true).update_all(
        can_add_cohort_clients: true,
        can_participate_in_cohorts: true,
        can_manage_inactive_cohort_clients: true,
    )

    Role.where(can_edit_assigned_cohorts: true).update_all(
        can_add_cohort_clients: true,
        can_participate_in_cohorts: true,
    )

    Role.where(can_view_assigned_cohorts: true).update_all(
        can_participate_in_cohorts: true,
    )
  end
end
