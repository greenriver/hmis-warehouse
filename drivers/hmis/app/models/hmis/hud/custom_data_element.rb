###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# "CustomDataElement" is NOT a HUD defined record type. Although it uses CamelCase conventions, this model is particular to Open Path. CamelCase is used for compatibility with "Appendix C - Custom file transfer template"in the HUD HMIS CSV spec. This specifies optional additional CSV files with the naming convention of Custom*.csv

class Hmis::Hud::CustomDataElement < Hmis::Hud::Base
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :CustomDataElements
  has_paper_trail(
    meta: {
      client_id: ->(r) { r.owner&.paper_trail_meta_value(:client_id) },
      enrollment_id: ->(r) { r.owner&.paper_trail_meta_value(:enrollment_id) },
      project_id: ->(r) { r.owner&.paper_trail_meta_value(:project_id) },
    },
  )

  include HasPiiAttributes
  pii_attr :value_string, as: :free_text, level: 2
  pii_attr :value_text, as: :free_text, level: 2
  pii_attr :value_date, as: :dob

  VALUE_COLUMNS = [
    :value_boolean,
    :value_date,
    :value_float,
    :value_integer,
    :value_json,
    :value_string,
    :value_text,
    :value_file_id,
  ].freeze

  belongs_to :owner, polymorphic: true, optional: false
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :custom_data_elements
  belongs_to :data_element_definition, class_name: 'Hmis::Hud::CustomDataElementDefinition', optional: false
  # SPECIAL CASE: with the addition of value_file, we are breaking the previous assumption that
  # > the CustomDataElement has an attribute value_[x] where "x" matches the CustomDataElementDefinition.field_type.
  # this is no longer true because the field name is value_file_id whereas the field_type is file.
  belongs_to :value_file, class_name: 'Hmis::File', optional: true, autosave: true, foreign_key: 'value_file_id', dependent: :destroy

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
    # Error if >1 value is set (like value_boolean and value_string)
    errors.add(:base, :invalid, message: 'has more than one value type') if values.size > 1
    return unless values.size == 1

    # Error if value_string is set but the definition says its a boolean type (for example)
    field_type = values.keys.first.gsub('value_', '')
    field_types_match = data_element_definition.field_type.to_s == field_type.to_s || data_element_definition.field_type == 'file' && field_type.to_s == 'file_id'
    errors.add(:base, :invalid, message: "has a value for '#{values.keys.first}' but definition is for type '#{data_element_definition.field_type}") unless field_types_match
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
    VALUE_COLUMNS.map do |f|
      if f == :value_file_id
        value_file
      else
        send(f)
      end
    end.compact.first
  end
end
