###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomServiceCategory" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomServiceCategory < Hmis::Hud::Base
  self.table_name = :CustomServiceCategories
  has_paper_trail

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  has_many :service_types, class_name: 'Hmis::Hud::CustomServiceType'
  has_many :form_instances, class_name: 'Hmis::Form::Instance'
  has_many :definitions, through: :form_instances

  def to_pick_list_option
    {
      code: id.to_s,
      label: name,
    }
  end
end
