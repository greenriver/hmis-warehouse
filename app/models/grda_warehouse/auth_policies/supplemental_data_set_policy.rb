###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::AuthPolicies
  SupplementalDataSetPolicy = Struct.new(:role_policy) do
    def show?
      role_policy.can_view_supplemental_client_data?
    end
  end
end
