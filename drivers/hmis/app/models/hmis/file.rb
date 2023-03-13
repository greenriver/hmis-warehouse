###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::File < GrdaWarehouse::File
  include ClientFileBase

  self.table_name = :files
  belongs_to :enrollment, class_name: '::Hmis::Hud::Enrollment', optional: true
  belongs_to :client, class_name: '::Hmis::Hud::Client'
end
