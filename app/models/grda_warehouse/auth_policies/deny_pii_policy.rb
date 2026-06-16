###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Policy that always denys PII access.
# Used in cases where we never want to show PII (see include_pii_in_detail_downloads config)
class GrdaWarehouse::AuthPolicies::DenyPiiPolicy
  include Singleton
  [
    :can_view,
    :can_view_name,
    :can_view_photo,
    :can_view_full_dob,
    :can_view_full_ssn,
    :can_view_hiv_status,
  ].each do |permission|
    method_name = :"#{permission}?"
    define_method(method_name) do
      false
    end
  end
end
