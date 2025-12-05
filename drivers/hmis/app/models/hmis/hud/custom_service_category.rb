###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  # Helper scope: non-empty categories that have at least one HUD service type (non-null hud_record_type)
  scope :with_hud_types, -> do
    joins(:service_types).where.not(service_types: { hud_record_type: nil }).distinct
  end

  # Helper scope: categories that have at least one custom service type (null hud_record_type). Includes empty categories
  scope :with_custom_types, -> do
    left_joins(:service_types).where(service_types: { hud_record_type: nil }).distinct
  end

  # Returns categories where all service types are HUD
  scope :hud_only, -> do
    with_hud_types.where.not(id: with_custom_types.select(:id))
  end

  # Returns categories where all service types are custom. Includes empty categories
  scope :custom_only, -> do
    with_custom_types.where.not(id: with_hud_types.select(:id))
  end

  def to_pick_list_option
    {
      code: id.to_s,
      label: name,
    }
  end
end
