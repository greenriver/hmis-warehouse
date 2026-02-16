###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::AuthPolicies::SupplementalDataSetPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  def can_view?
    # supplemental data sets do not support legacy role-based permissions
    return false unless user.using_acls?

    permission = :can_view_supplemental_client_data

    # check the permission on the data set (from collections)
    return false unless context.supplemental_data_set_role_permissions(data_set.id).include?(permission)

    # additional data source permission requirement, specific to supplemental data
    return false unless context.data_source_role_permissions(data_set.data_source_id).include?(permission)

    return true
  end

  protected

  def data_set = resource

  def validate_resource!(arg) = ensure_arg_type!(arg, HmisSupplemental::DataSet)
end
