# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    :file,
  ].freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :assessments
  has_many :values, class_name: 'Hmis::Hud::CustomDataElement', inverse_of: :data_element_definition, foreign_key: :data_element_definition_id
  belongs_to :form_definition, primary_key: 'identifier', foreign_key: 'form_definition_identifier', class_name: 'Hmis::Form::Definition', optional: true

  validates :field_type, inclusion: { in: FIELD_TYPES.map(&:to_s) }, allow_blank: false
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

  def cde_arel_field
    cde_t = Hmis::Hud::CustomDataElement.arel_table
    case field_type.to_sym
    when :float
      cde_t[:value_float]
    when :integer
      cde_t[:value_integer]
    when :boolean
      cde_t[:value_boolean]
    when :string
      cde_t[:value_string]
    when :text
      cde_t[:value_text]
    when :date
      cde_t[:value_date]
    when :json
      cde_t[:value_json]
    when :file
      cde_t[:value_file]
    else
      raise ArgumentError, "Invalid field type: #{field_type}"
    end
  end

  def read_value_from(custom_data_element)
    raise ArgumentError, "CustomDataElementDefinition ID mismatch: #{custom_data_element.data_element_definition_id} != #{id}" if custom_data_element.data_element_definition_id != id

    case field_type.to_sym
    when :float
      custom_data_element.value_float
    when :integer
      custom_data_element.value_integer
    when :boolean
      custom_data_element.value_boolean
    when :string
      custom_data_element.value_string
    when :text
      custom_data_element.value_text
    when :date
      custom_data_element.value_date
    when :json
      custom_data_element.value_json
    when :file
      custom_data_element.value_file
    else
      raise ArgumentError, "Invalid field type: #{field_type}"
    end
  end
end
