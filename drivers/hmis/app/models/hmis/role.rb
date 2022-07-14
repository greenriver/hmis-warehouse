###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Role < ::User
  belongs_to :user_hmis_data_source_roles
  has_many :users, thorugh: :user_hmis_data_source_roles
end
