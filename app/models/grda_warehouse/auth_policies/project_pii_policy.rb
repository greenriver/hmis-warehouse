###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# FIXME: for a report context, we only have a project id of an enrollment to determine PII. This is efficient but the
# permissions not entirely accurate in every case. We are not including permissions granted by all the client's
# enrollments or direct client-record visibility
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

  def validate_resource!(arg)
    ensure_arg_type!(arg, Integer)
  end

  def project_id
    resource
  end

  def role_permissions
    context.project_role_permissions(project_id)
  end
end
