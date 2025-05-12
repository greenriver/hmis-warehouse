# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Often reports display client PII from the destination client (sometimes the source client for DQ). Using this project
# PII policy grants access to PII based only on the client/project which may be more restrictive than permissions
# granted through the full set of source clients
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
      resource_permissions.include?(permission)
    end
  end

  def initialize(context:, resource:)
    resource_id = resource.is_a?(GrdaWarehouse::Hud::Project) ? resource.id : resource
    super(context: context, resource: resource_id)
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, Integer)
  end

  def project_id
    resource
  end

  def resource_permissions
    context.project_role_permissions(project_id)
  end
end
