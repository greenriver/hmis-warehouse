###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ClientAlert < Hmis::HmisBase
  belongs_to :created_by, class_name: 'Hmis::User'
  belongs_to :client, class_name: 'Hmis::Hud::Client'
end
