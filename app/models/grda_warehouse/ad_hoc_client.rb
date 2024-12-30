###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AdHocClient < GrdaWarehouseBase
  acts_as_paranoid

  include HasPiiAttributes
  pii_attr :first_name
  pii_attr :middle_name
  pii_attr :last_name
  pii_attr :dob
  pii_attr :ssn

  belongs_to :ad_hoc_data_source, optional: true
  belongs_to :ad_hoc_batch, foreign_key: :batch_id
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
end
