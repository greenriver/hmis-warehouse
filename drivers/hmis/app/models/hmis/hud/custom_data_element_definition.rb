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

  FIELD_TYPE_TO_COLUMN = {
    float: :value_float,
    integer: :value_integer,
    boolean: :value_boolean,
    string: :value_string,
    text: :value_text,
    date: :value_date,
    json: :value_json,
    file: :value_file,
  }.freeze

  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
  belongs_to :user, **hmis_relation(:UserID, 'User'), optional: true, inverse_of: :assessments
  has_many :values, class_name: 'Hmis::Hud::CustomDataElement', inverse_of: :data_element_definition, foreign_key: :data_element_definition_id
  belongs_to :form_definition, primary_key: 'identifier', foreign_key: 'form_definition_identifier', class_name: 'Hmis::Form::Definition', optional: true

  validates :field_type, inclusion: { in: FIELD_TYPES.map(&:to_s) }, allow_blank: false
  validates_format_of :key, with: /\A[a-zA-Z0-9_-]*\z/

  # reporting_key is stricter than key. Must be lowercase, start with a letter, no hyphens, max 63 chars
  validates_format_of :reporting_key, with: /\A[a-z][a-z0-9_]{0,62}\z/, allow_nil: true

  scope :for_type, ->(owner_type) do
    where(owner_type: owner_type)
  end

  scope :for_custom_assessments, -> { for_type(Hmis::Hud::CustomAssessment.sti_name) }
  scope :for_hud_services, -> { for_type(Hmis::Hud::Service.sti_name) }
  scope :for_custom_services, -> { for_type(Hmis::Hud::CustomService.sti_name) }
  scope :for_hud_or_custom_services, -> { for_type([Hmis::Hud::Service.sti_name, Hmis::Hud::CustomService.sti_name]) }
  scope :for_clients, -> { for_type(Hmis::Hud::Client.sti_name) }

  use_enum_with_same_key :form_role_enum_map, FIELD_TYPES.map { |f| [f, f.to_s.humanize] }.to_h

  # Generate and set a valid, unique reporting_key for this instance.
  # Caller is responsible for saving the instance.
  # @param unpersisted_reserved_keys [Set<Array>] Optional set of [owner_type, reporting_key] pairs
  # that are reserved (we must avoid conflicting with them),
  # but aren't yet persisted (so a call to `exists?` won't find them).
  # @return [String] The generated reporting_key
  def generate_reporting_key(unpersisted_reserved_keys: Set.new)
    self.reporting_key = self.class.generate_reporting_key(key, owner_type: owner_type, unpersisted_reserved_keys: unpersisted_reserved_keys)
  end

  # Generate a valid, unique reporting_key from a given key.
  # Exposed as a class method for use when bulk creating CDEDs.
  # See comment on the instance method above.
  def self.generate_reporting_key(key, owner_type:, unpersisted_reserved_keys: Set.new)
    # Lowercase and replace non-alphanumeric characters with underscores
    normalized = key.downcase.gsub(/[^a-z0-9_]/, '_')

    # Ensure it starts with a letter
    normalized = "k_#{normalized}" unless normalized.match?(/\A[a-z]/)

    # Truncate to 63 characters
    normalized = normalized[0..62]

    # Check uniqueness
    return normalized unless reporting_key_exists?(normalized, owner_type, unpersisted_reserved_keys)

    # Try to make it unique by appending a number
    count = 1
    max_attempts = 50

    while count <= max_attempts
      suffix = "_#{count}"
      # Truncate base to leave room for suffix
      base_length = 63 - suffix.length
      candidate = "#{normalized[0...base_length]}#{suffix}"

      return candidate unless reporting_key_exists?(candidate, owner_type, unpersisted_reserved_keys)

      count += 1
    end

    raise "Unique reporting_key generation failed after #{max_attempts} attempts for key: #{key}"
  end

  # Check if a reporting_key exists either in the database or in unpersisted reserved keys if provided
  def self.reporting_key_exists?(reporting_key, owner_type, unpersisted_reserved_keys = Set.new)
    return true if unpersisted_reserved_keys.include?([owner_type, reporting_key])

    exists?(owner_type: owner_type, reporting_key: reporting_key)
  end

  def cde_arel_field
    cde_t = Hmis::Hud::CustomDataElement.arel_table
    column_name = FIELD_TYPE_TO_COLUMN[field_type.to_sym]
    raise ArgumentError, "Invalid field type: #{field_type}" unless column_name

    cde_t[column_name]
  end
end
