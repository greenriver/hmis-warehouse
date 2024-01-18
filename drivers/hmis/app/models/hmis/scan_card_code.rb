###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ScanCardCode < Hmis::HmisBase
  self.table_name = 'hmis_scan_card_codes'
  acts_as_paranoid
  has_paper_trail

  belongs_to :client, optional: false, class_name: 'Hmis::Hud::Client'
  belongs_to :created_by, class_name: 'Hmis::User', optional: true
  belongs_to :deleted_by, class_name: 'Hmis::User', optional: true
end
