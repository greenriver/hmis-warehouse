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
  has_many :definitions, through: :form_instances, source: :definitions

  validates_presence_of :name, allow_blank: false

  scope :non_hud, -> do
    # Returns categories that are empty or have any service type with a null hud_record_type.
    # Excludes "stock" categories that are seeded initially, which only contain HUD service types.
    left_joins(:service_types).where(service_types: { hud_record_type: nil }).distinct
  end

  def to_pick_list_option
    {
      code: id.to_s,
      label: name,
    }
  end
end
