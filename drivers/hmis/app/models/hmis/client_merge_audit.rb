###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ClientMergeAudit < Hmis::HmisBase
  belongs_to :actor, class_name: 'Hmis::User'
  has_many :client_merge_histories, class_name: 'Hmis::ClientMergeHistory', inverse_of: :client_merge_audit
  has_many :retained_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories
  has_many :deleted_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories

  has_one :most_recent_merge_history, -> { order(updated_at: :desc) }, class_name: 'Hmis::ClientMergeHistory'
  has_one :retained_client, class_name: 'Hmis::Hud::Client', through: :most_recent_merge_history

  scope :viewable_by, ->(user) do
    joins(:retained_client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def self.apply_filters(input)
    Hmis::Filter::ClientMergeAuditFilter.new(input).filter_scope(self)
  end

  # Get pre-merge mappings for a specific record type
  # @param record_type [String] The key in pre_merge_mappings (e.g., 'enrollments', 'names')
  # @return [Hash] Mapping of record_id => { attribute_name => original_value }
  def mappings_for(record_type)
    (pre_merge_mappings[record_type.to_s] || {}).transform_keys(&:to_i)
  end

  # Get all enrollment IDs that were moved during this merge
  # @return [Array<Integer>] Array of enrollment IDs
  def enrollment_ids
    mappings_for('enrollments').keys
  end

  # Get the original PersonalID for a specific enrollment
  # @param enrollment_id [Integer] The enrollment ID (primary key)
  # @return [String, nil] The original PersonalID, or nil if not found
  def original_personal_id_for_enrollment(enrollment_id)
    mapping_data = mappings_for('enrollments')[enrollment_id]
    mapping_data&.dig('PersonalID')
  end

  # Get the original client_id for a specific record (for client_id-based records like files)
  # @param record_type [String] The record type (e.g., 'files', 'scan_cards')
  # @param record_id [Integer] The record ID
  # @return [Integer, nil] The original client_id, or nil if not found
  def original_client_id_for(record_type, record_id)
    mappings_for(record_type)[record_id]&.dig('client_id')&.to_i
  end

  # Get the original source_id for a specific record (for source_id-based records like mci_ids)
  # @param record_type [String] The record type (e.g., 'mci_ids', 'mci_unique_ids')
  # @param record_id [Integer] The record ID
  # @return [Integer, nil] The original source_id, or nil if not found
  def original_source_id_for(record_type, record_id)
    mappings_for(record_type)[record_id]&.dig('source_id')&.to_i
  end

  # Get the original warehouse destination_id for a merged source client
  # @param client_id [Integer] The source client ID
  # @return [Integer, nil] The original warehouse destination client ID, or nil if not found
  def original_warehouse_destination_id(client_id)
    mappings_for('source_clients')[client_id]&.dig('destination_id')&.to_i
  end

  # Get IDs of records that were destroyed during merge
  # @param record_type [String] The record type (e.g., 'custom_data_elements', 'referral_household_members')
  # @return [Array<String>] Array of destroyed record IDs as strings
  def destroyed_record_ids(record_type)
    key = "destroyed_#{record_type}"
    pre_merge_mappings[key] || []
  end

  # Check if a specific record was destroyed during merge
  # @param record_type [String] The record type
  # @param record_id [Integer] The record ID
  # @return [Boolean] True if the record was destroyed
  def record_destroyed?(record_type, record_id)
    destroyed_record_ids(record_type).include?(record_id.to_s)
  end
end
