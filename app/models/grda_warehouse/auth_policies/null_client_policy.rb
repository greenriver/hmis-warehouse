###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::NullClientPolicy
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
