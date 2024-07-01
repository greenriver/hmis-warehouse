###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomDataElementDefinition" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomDataElementDefinition < Hmis::Hud::Base
  include Hmis::Hud::Concerns::HasEnums
  self.table_name = :CustomDataElementDefinitions
  has_paper_trail

  FIELD_TYPES = [
    :float,
    :integer,
    :boolean,
    :string,
    :text,
    :date,
    :json,
  ].freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :assessments
  has_many :values, class_name: 'Hmis::Hud::CustomDataElement', inverse_of: :data_element_definition, foreign_key: :data_element_definition_id
  belongs_to :form_definition, primary_key: 'identifier', foreign_key: 'form_definition_identifier', class_name: 'Hmis::Form::Definition', optional: true

  validates_format_of :key, with: /\A[a-zA-Z0-9_-]*\z/

  scope :for_type, ->(owner_type) do
    where(owner_type: owner_type)
  end

  scope :for_custom_assessments, -> { for_type(Hmis::Hud::CustomAssessment.sti_name) }
  scope :for_hud_services, -> { for_type(Hmis::Hud::Service.sti_name) }
  scope :for_custom_services, -> { for_type(Hmis::Hud::CustomService.sti_name) }
  scope :for_hud_or_custom_services, -> { for_type([Hmis::Hud::Service.sti_name, Hmis::Hud::CustomService.sti_name]) }
  scope :for_clients, -> { for_type(Hmis::Hud::Client.sti_name) }

  use_enum_with_same_key :form_role_enum_map, FIELD_TYPES.map { |f| [f, f.to_s.humanize] }.to_h
end
