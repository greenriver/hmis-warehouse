###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomServiceCategory < Hmis::Hud::Base
  self.table_name = :CustomServiceCategories

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User')
  has_many :service_types, class_name: 'Hmis::Hud::CustomServiceType'

  def to_pick_list_option
    {
      code: id.to_s,
      label: name,
    }
  end
end
