###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::DenyPolicy
  include Singleton

  Role.permissions.each do |permission|
    define_method :"#{permission}?" do
      false
    end
  end
end
