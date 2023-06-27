###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Hud::CustomDataElement < Hmis::Hud::Base
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :CustomDataElements

  VALUE_COLUMNS = [
    :value_boolean,
    :value_date,
    :value_float,
    :value_integer,
    :value_json,
    :value_string,
    :value_text,
  ].freeze

  belongs_to :owner, polymorphic: true, optional: false
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), inverse_of: :assessments
  belongs_to :data_element_definition, class_name: 'Hmis::Hud::CustomDataElementDefinition', optional: false
  delegate :key, :label, :repeats, to: :data_element_definition

  # Enforce that owner_type is correct for the Data Element Definition
  validate :validate_owner_types_match
  validate :validate_exactly_one_value

  # Enforce the "repeats" value of the Custom Data Element Definition.
  # Some custom elements can have multiple values per record, for example "Primary Languages"
  # Other custom elements can only have one value per record, like "Move-in Date Comment"
  validates_uniqueness_of :owner_id,
                          scope: [:owner_type, :data_element_definition],
                          conditions: -> { joins(:data_element_definition).where(cded_t[:repeats].eq(false)) }

  scope :of_type, ->(data_element_definition) do
    where(data_element_definition: data_element_definition)
  end

  def validate_owner_types_match
    errors.add(:owner_type, :invalid) if data_element_definition.owner_type != owner_type
  end

  def validate_exactly_one_value
    values = slice(VALUE_COLUMNS).compact
    errors.add(:base, :invalid, full_message: 'Exactly one value must be provided') unless values.size == 1
    return unless values.size == 1

    field_type = values.keys.first.gsub('value_', '')
    errors.add(:base, :invalid, full_message: "Found value for '#{values.keys.first}' but definition is for type '#{data_element_definition.field_type}") unless data_element_definition.field_type.to_s == field_type.to_s
  end

  def equal_for_merge?(other)
    columns = [:data_element_definition_id, *VALUE_COLUMNS]

    columns.all? do |col|
      if [:value_string, :value_text].include?(col)
        send(col)&.strip&.downcase == other.send(col)&.strip&.downcase
      else
        send(col) == other.send(col)
      end
    end
  end

  def value
    VALUE_COLUMNS.map { |f| send(f) }.compact.first
  end
end
