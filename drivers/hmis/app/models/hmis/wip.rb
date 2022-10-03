###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Wip < GrdaWarehouseBase
  belongs_to :source, polymorphic: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :project, class_name: '::Hmis::Hud::Project', optional: true
end
