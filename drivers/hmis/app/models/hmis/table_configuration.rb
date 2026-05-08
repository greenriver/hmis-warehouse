###
# Copyright Green River Data Group, Inc.
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
  CE_CLIENTS = 'ce_clients'
  TABLE_KEYS = [
    CE_CLIENTS,
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

  scope :for_ce_clients_table, -> { where(table_key: CE_CLIENTS) }

  def column_keys
    Array.wrap(columns).filter_map { |col| col['key'] || col[:key] }.map(&:to_s)
  end

  # Detect config to use for CE Eligible Clients table for a given data source
  def self.detect_ce_clients_global_config(data_source_id:)
    detect_ce_clients_config(data_source_id: data_source_id)
  end

  # Detect config to use for CE Eligible Clients table, optionally scoped to a Project Group
  def self.detect_ce_clients_config(data_source_id:, project_group_id: nil)
    project_group = Hmis::ProjectGroup.find_by(id: project_group_id, data_source_id: data_source_id) if project_group_id.present?
    if project_group
      config = Hmis::TableConfiguration.for_ce_clients_table.
        where(data_source_id: data_source_id).
        find_by(owner: project_group)
      return config if config.present?
    end

    Hmis::TableConfiguration.for_ce_clients_table.find_by(data_source_id: data_source_id, owner: nil)
  end

  # Detect config to use for CE Eligible Clients table for a given unit group
  def self.detect_ce_clients_unit_group_config(data_source_id:, unit_group_id:, project_group_id: nil)
    unit_group = Hmis::UnitGroup.find_by(id: unit_group_id)
    return unless unit_group

    project_group = Hmis::ProjectGroup.find_by(id: project_group_id, data_source_id: data_source_id) if project_group_id.present?

    # find applicable configuration for this unit group, preferring more specific owners
    [
      unit_group,
      unit_group.project,
      project_group || detect_unambiguous_project_group_config_owner(data_source_id: data_source_id, project: unit_group.project),
      unit_group.project&.organization,
      nil,
    ].each do |owner|
      next if owner.blank? && !owner.nil?

      found = Hmis::TableConfiguration.for_ce_clients_table.
        where(data_source_id: data_source_id).
        find_by(owner: owner)
      return found if found.present?
    end

    nil # no config found
  end

  def self.detect_unambiguous_project_group_config_owner(data_source_id:, project:)
    return unless project

    configured_project_groups = project.project_groups.
      joins("INNER JOIN #{quoted_table_name} ON #{quoted_table_name}.owner_type = 'Hmis::ProjectGroup' AND #{quoted_table_name}.owner_id = hmis_project_groups.id").
      merge(Hmis::TableConfiguration.for_ce_clients_table.where(data_source_id: data_source_id)).
      distinct

    configured_project_groups.one? ? configured_project_groups.first : nil
  end

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
