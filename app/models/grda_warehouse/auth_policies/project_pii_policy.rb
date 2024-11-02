###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::ProjectPiiPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  [
    [:can_view_client_name, :can_view_name?],
    [:can_view_client_photo, :can_view_photo?],
    [:can_view_full_dob],
    [:can_view_full_ssn],
    [:can_view_hiv_status],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      role_permissions.include?(permission)
    end
  end

  protected

  def project_id
    resource.project_id
  end

  def role_permissions
    context.project_role_permissions(project_id)
  end
end
