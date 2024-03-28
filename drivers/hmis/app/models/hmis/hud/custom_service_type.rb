###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomServiceType" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomServiceType < Hmis::Hud::Base
  self.table_name = :CustomServiceTypes
  has_paper_trail

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true
  belongs_to :custom_service_category
  has_many :custom_services

  alias_attribute :category, :custom_service_category

  validates :hud_record_type, uniqueness: { scope: [:hud_type_provided] }, allow_nil: true
  validates :name, uniqueness: { scope: [:custom_service_category] }
  validates_with Hmis::Hud::Validators::CustomServiceTypeValidator

  def hud_service?
    hud_record_type.present?
  end

  def to_pick_list_option
    {
      code: id.to_s,
      label: name,
      group_label: custom_service_category.name,
    }
  end
end
