###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-auth-policies.md
class GrdaWarehouse::AuthPolicies::CohortPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # Permissions that only count when the user can also view the cohort
  [
    [:can_add_cohort_clients, :can_add_clients?],
    [:can_manage_cohort_data, :can_manage_data?],
    [:can_participate_in_cohorts, :can_participate?],
    [:can_manage_inactive_cohort_clients, :can_manage_inactive_clients?],
    [:can_view_deleted_cohort_clients, :can_view_deleted_clients?],
    [:can_download_cohorts, :can_download?],
    [:can_edit_cohort_columns, :can_edit_columns?],
    [:can_view_cohort_client_changes_report, :can_view_changes_report?],
  ].each do |permission, method_name|
    define_method(method_name) do
      permission?(permission)
    end
  end

  # Does the user hold any view, participate, manage-data or configure permission on this cohort?
  def can_list?
    (resource_permissions & [
      :can_view_cohorts,
      :can_participate_in_cohorts,
      :can_manage_cohort_data,
      :can_configure_cohorts,
    ]).any?
  end

  # Matches the defaults of Cohort.viewable_by
  def can_view?
    (GrdaWarehouse::Cohort.viewable_permissions + GrdaWarehouse::Cohort.editable_permissions).any? do |permission|
      resource_permissions.include?(permission)
    end
  end
  memoize :can_view?

  # Configuring does not imply viewing
  def can_configure?
    resource_permissions.include?(:can_configure_cohorts)
  end

  def can_view_inactive_clients?
    permission?(:can_view_inactive_cohort_clients) || permission?(:can_manage_inactive_cohort_clients)
  end

  def can_update_data?
    can_manage_data? || can_participate? || can_manage_inactive_clients?
  end

  def can_edit_clients?
    can_manage_data? || can_participate?
  end

  # True when the user can view the cohort and holds the permission through it
  def permission?(permission)
    can_view? && resource_permissions.include?(permission)
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Cohort)
  end

  def resource_permissions
    context.cohort_role_permissions(resource.id)
  end
end
