###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Some reports now require a pii policy. In cases where that is not available, this policy matches
# the system behavior prior to this implementation, allowing all fields to be visible.
class GrdaWarehouse::AuthPolicies::LegacyPiiPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  [
    [:can_view_client_name, :can_view_name?],
    [:can_view_client_photo, :can_view_photo?],
    [:can_view_full_dob],
    [:can_view_full_ssn],
    [:can_view_hiv_status],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      true
    end
  end

  protected

  def validate_resource!(_arg)
    true
  end
end
