###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

###
# HMIS Table Configuration
#
# The HMIS table configuration functionality allows for dynamic customization of table views in the HMIS application.
# This feature supports both global and owner-specific configurations, enabling flexibility for different use cases.
#
# ## Key Features
# - **Dynamic Column Configuration**: Define additional columns to be displayed in the table. Must be coupled
#      with dynamic column implementation on the frontend.
# - **Dynamic Filter Configuration**: Define custom filters to be available on the table. Must be coupled with
#      dynamic filter implementation the frontend and on the relevant Model, see `CeClientFilter` class for an example.
#
# ## Database Schema
# The `hmis_table_configurations` table stores the configurations:
# - `data_source_id`: Identifies the HMIS data source the configuration belongs to.
# - `table_key`: A unique key identifying the table (or set of tables) being configured.
# - `owner`: A polymorphic reference to the owner of the configuration (e.g., `Project`).
# - `columns`: A JSONB field storing column configurations.
# - `filters`: A JSONB field storing filter configurations.
class Hmis::TableConfiguration < Hmis::HmisBase
  CE_WAITLIST = 'ce_waitlist'
  TABLE_KEYS = [
    CE_WAITLIST,
  ].freeze

  COLUMN_TYPES = [
    'string',
    'date',
    # add other types here
  ].freeze
  FILTER_TYPES = [
    'select',
    # add other types here
  ].freeze

  belongs_to :owner, polymorphic: true, optional: true
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  validates :table_key, inclusion: { in: TABLE_KEYS }
  validates :table_key, presence: true, uniqueness: { scope: [:owner_type, :owner_id, :data_source_id], message: 'must be unique per owner' }

  validate :validate_columns_shape
  validate :validate_filters_shape

  scope :for_ce_waitlist, -> { where(table_key: CE_WAITLIST) }

  private

  # Column Config Example:
  # [
  #   {
  #     "key": "cde.custom_assessment.my_prioritization_score",
  #     "type": "string",
  #     "label": "My Score"
  #   },
  #   {
  #     "key": "cde.custom_assessment.my_household_type",
  #     "type": "string",
  #     "label": "Household Type"
  #   }
  # ]
  def validate_columns_shape
    return if columns.is_a?(Array) && columns.all? do |col|
      col.is_a?(Hash) &&
        col.key?('key') && col['key'].is_a?(String) &&
        col.key?('label') && col['label'].is_a?(String) &&
        col.key?('type') && col['type'].is_a?(String) && COLUMN_TYPES.include?(col['type'])
    end

    errors.add(:columns, 'must be an array of hashes with keys "key" (string), "label" (string), and "type" (valid column type)')
  end

  # Example:
  # [
  #   {
  #     "key": "cde.custom_assessment.my_prioritization_score",
  #     "label": "My Score",
  #     "type": "select",
  #     "options": [
  #       { "code": "1"},
  #       { "code": "2"},
  #       { "code": "3"},
  #       { "code": "4"},
  #       { "code": "5"},
  #       { "code": "6"},
  #       { "code": "7"},
  #       { "code": "8"},
  #       { "code": "9"},
  #       { "code": "10"}
  #     ]
  #   }
  # ]
  def validate_filters_shape
    return unless filters.is_a?(Array)

    filters.each do |filter|
      unless filter.is_a?(Hash)
        errors.add(:filters, 'each filter must be a hash')
        next
      end

      unless filter.key?('key') && filter['key'].is_a?(String)
        errors.add(:filters, 'each filter must have a "key" (string)')
        next
      end

      unless filter.key?('label') && filter['label'].is_a?(String)
        errors.add(:filters, 'each filter must have a "label" (string)')
        next
      end

      unless filter.key?('type') && filter['type'].is_a?(String) && FILTER_TYPES.include?(filter['type'])
        errors.add(:filters, 'each filter must have a "type" (string)')
        next
      end

      next unless filter['type'] == 'select'

      unless filter.key?('options') && filter['options'].is_a?(Array)
        errors.add(:filters, 'select filters must have an "options" array')
        next
      end

      filter['options'].each do |opt|
        next if opt.is_a?(Hash) && opt.key?('code') && opt['code'].is_a?(String)

        errors.add(:filters, 'each option in "options" must be a hash with "code" (string) and optional "label" (string)')
      end
    end
  end
end
