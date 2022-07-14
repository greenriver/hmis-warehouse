###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::UserHmisDataSourceRole < ::User
  belongs_to :user
  belongs_to :role
  belongs_to :data_source
end
