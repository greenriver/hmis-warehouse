###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Agencies can mark individual clients to be excluded from exports. When a client
# is flagged, they are omitted from both the client and enrollment rows of every
# affected HMIS CSV export.
#
# Usage:
#   svc = ClientExternalDataSharing.new(client)
#   svc.excluded?                           # => true/false
#   svc.set_exclusion!(value: true, user:)  # persist the flag + audit trail
#   svc.last_update                         # => { updated_at:, updated_by: } or nil
#   svc.last_update_text                    # => human-readable string or nil
#
# Scope filtering (used by Export::Scopes):
#   ClientExternalDataSharing.remove_excluded_clients(scope)     # applies both exclusions
#   ClientExternalDataSharing.remove_excluded_enrollments(scope) # applies both exclusions
#
# Granular scope filtering (apply a single exclusion type):
#   ClientExternalDataSharing.exclude_from_external(scope)             # clients: explicit flag
#   ClientExternalDataSharing.exclude_for_embargo(scope)               # clients: newly added
#   ClientExternalDataSharing.exclude_enrollments_from_external(scope) # enrollments: explicit flag
#   ClientExternalDataSharing.exclude_enrollments_for_embargo(scope)   # enrollments: newly added
#
# The feature is gated by the :enable_external_data_sharing_exclusion config
# flag. When disabled, the remove_excluded_* methods return the scope unchanged.
# The granular methods do NOT check the flag — callers are responsible for gating.
class ClientExternalDataSharing
  EMBARGO_PERIOD = 1.week

  # Keys and labels for every export mechanism that honours the exclusion flag.
  # Add a new entry here whenever a new export type starts enforcing exclusion.
  EXCLUSION_TARGETS = {
    hmis_csv_export: 'HMIS CSV Export',
  }.freeze

  def self.exclusion_target_labels
    EXCLUSION_TARGETS.values
  end

  def self.enabled?
    GrdaWarehouse::Config.get(:enable_external_data_sharing_exclusion)
  end

  def self.remove_excluded_clients(scope)
    return scope unless enabled?

    scope = exclude_from_external(scope)
    scope = exclude_for_embargo(scope)
    scope
  end

  def self.remove_excluded_enrollments(scope)
    return scope unless enabled?

    scope = exclude_enrollments_from_external(scope)
    scope = exclude_enrollments_for_embargo(scope)
    scope
  end

  def self.exclude_from_external(scope)
    scope.where.not(id: externally_excluded_client_ids)
  end

  def self.exclude_for_embargo(scope)
    scope.where.not(id: embargoed_client_ids)
  end

  def self.exclude_enrollments_from_external(scope)
    wc_t = GrdaWarehouse::WarehouseClient.arel_table
    scope.
      joins(client: :warehouse_client_source).
      where(wc_t[:destination_id].not_in(externally_excluded_client_ids.arel))
  end

  def self.exclude_enrollments_for_embargo(scope)
    wc_t = GrdaWarehouse::WarehouseClient.arel_table
    scope.
      joins(client: :warehouse_client_source).
      where(wc_t[:destination_id].not_in(embargoed_client_ids.arel))
  end

  def self.externally_excluded_client_ids
    GrdaWarehouse::ClientAttribute.
      where(external_data_sharing_exclusion_flag: true).
      select(:client_id)
  end

  def self.embargoed_client_ids
    GrdaWarehouse::WarehouseClient.
      group(:destination_id).
      having('MIN(created_at) > ?', EMBARGO_PERIOD.ago).
      select(:destination_id)
  end

  def initialize(client)
    @client = client
  end

  def excluded?
    GrdaWarehouse::ClientAttribute.exists?(
      client_id: @client.id,
      external_data_sharing_exclusion_flag: true,
    )
  end

  def embargo_expires_at
    earliest = GrdaWarehouse::WarehouseClient.
      where(destination_id: @client.id).
      minimum(:created_at)
    return unless earliest

    earliest + EMBARGO_PERIOD
  end

  def embargoed?
    expires = embargo_expires_at
    expires.present? && expires > Time.current
  end

  def set_exclusion!(value:, user: nil)
    record = GrdaWarehouse::ClientAttribute.find_or_initialize_by(client_id: @client.id)
    record.update!(
      external_data_sharing_exclusion_flag: value,
      external_data_sharing_updated_by: user&.id || User.system_user.id,
      external_data_sharing_updated_at: Time.current,
    )
  end

  def last_update
    record = GrdaWarehouse::ClientAttribute.find_by(client_id: @client.id)
    return if record.nil? || record.external_data_sharing_exclusion_flag.nil?

    user_name = User.find_by(id: record.external_data_sharing_updated_by)&.name || 'System'
    { updated_at: record.external_data_sharing_updated_at, updated_by: user_name }
  end

  def last_update_text
    info = last_update
    return unless info

    "Last updated #{I18n.l(info[:updated_at], format: :table_compact)} by #{info[:updated_by]}"
  end
end
