###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Sends emails when metric thresholds are crossed. Invoked after threshold collection (e.g. by
# CsvImportMonitorCollector). Each user receives a single email per job run covering all alert types
# they are subscribed to.
#
# Recipients differ by alert type:
#
# - CSV import: thresholds are per-data-source, per-CSV-file (ImportCsvMonitor). Each monitor has
#   its own config and recipients. NotificationConfiguration (source: ImportCsvMonitor) stores who
#   gets notified for that specific monitor.
#
# - Other metrics: thresholds apply globally (e.g. client Homeless Days). Users subscribe to the
#   alert type via ContactAlertSubscription on AlertDefinition, not to a specific entity.
class NotifyMetricThresholdCrossingsJob < BaseJob
  queue_as ENV.fetch('DJ_DEFAULT_QUEUE_NAME', :default)
  queue_with_priority 10

  CSV_IMPORT_ALERT_CODE = 'csv_import_threshold_exceeded'

  def perform(calculation_date = Date.current)
    lock_name = 'notify_metric_threshold_crossings_job'
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0) do
      crossings_by_alert = GrdaWarehouse::Monitoring::MetricDefinition.
        active.
        threshold_crossings_for_alerts(calculation_date)

      return if crossings_by_alert.empty?

      # Build a single user_id => { metric_id => crossing_info } map across ALL alert types
      all_user_crossings = Hash.new { |h, k| h[k] = {} }

      crossings_by_alert.each do |alert_code, crossings_by_metric|
        if alert_code == CSV_IMPORT_ALERT_CODE
          merge_csv_import_user_crossings(all_user_crossings, crossings_by_metric)
        else
          merge_contact_subscriber_crossings(all_user_crossings, alert_code, crossings_by_metric)
        end
      end

      return if all_user_crossings.empty?

      # Batch-load users once, then send one email per user
      users_by_id = User.where(id: all_user_crossings.keys).active.index_by(&:id)

      all_user_crossings.each do |user_id, crossings|
        user = users_by_id[user_id]
        next unless user&.active?

        NotifyUser.metric_threshold_crossed(
          user_id: user.id,
          crossings: crossings,
          calculation_date: calculation_date,
        ).deliver_now
      end
    end
  end

  private

  # CSV import: merges crossings into all_user_crossings based on NotificationConfiguration on
  # each ImportCsvMonitor. Uses batch queries to avoid N+1.
  def merge_csv_import_user_crossings(all_user_crossings, crossings_by_metric)
    return unless defined?(GrdaWarehouse::ImportCsvMonitor)
    return if crossings_by_metric.empty?

    # Batch-load all needed MetricDefinitions
    metric_defs_by_id = GrdaWarehouse::Monitoring::MetricDefinition.
      where(id: crossings_by_metric.keys).
      index_by(&:id)

    # Collect data_source_id + csv_file_name pairs from all crossings
    entity_id_and_file_pairs = crossings_by_metric.flat_map do |metric_id, snapshot_info|
      metric_def = metric_defs_by_id[metric_id]
      next [] unless metric_def&.subtype.present?

      (snapshot_info[:data] || []).map { |c| [c[:entity_id], metric_def.subtype] }
    end.uniq

    return if entity_id_and_file_pairs.empty?

    # Batch-load monitors
    data_source_ids = entity_id_and_file_pairs.map(&:first).uniq
    csv_file_names = entity_id_and_file_pairs.map(&:last).uniq
    monitors_by_key = GrdaWarehouse::ImportCsvMonitor.
      where(data_source_id: data_source_ids, csv_file_name: csv_file_names, active: true).
      index_by { |m| [m.data_source_id, m.csv_file_name] }

    return if monitors_by_key.empty?

    # Batch-load notification configs for all monitors
    user_ids_by_monitor_id = GrdaWarehouse::NotificationConfiguration.
      where(
        source_type: 'GrdaWarehouse::ImportCsvMonitor',
        source_id: monitors_by_key.values.map(&:id),
        notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
        active: true,
      ).
      group_by(&:source_id).
      transform_values { |configs| configs.filter_map(&:user_id).uniq }

    crossings_by_metric.each do |metric_id, snapshot_info|
      metric_def = metric_defs_by_id[metric_id]
      next unless metric_def&.subtype.present?

      csv_file_name = metric_def.subtype

      (snapshot_info[:data] || []).each do |crossing|
        monitor = monitors_by_key[[crossing[:entity_id], csv_file_name]]
        next unless monitor

        (user_ids_by_monitor_id[monitor.id] || []).each do |user_id|
          all_user_crossings[user_id][metric_id] ||= {
            display_name: snapshot_info[:display_name],
            data: [],
            total_count: 0,
            truncated: snapshot_info[:truncated],
            entity_label: metric_def.entity_label,
          }
          all_user_crossings[user_id][metric_id][:data] << crossing
          all_user_crossings[user_id][metric_id][:total_count] += 1
        end
      end
    end
  end

  # Non-CSV alerts: merges crossings into all_user_crossings for all users subscribed via
  # ContactAlertSubscription on the AlertDefinition.
  def merge_contact_subscriber_crossings(all_user_crossings, alert_code, crossings_by_metric)
    alert_definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
    return unless alert_definition

    subscribed_users = subscribed_active_users_for_alert(alert_definition)
    return if subscribed_users.empty?

    subscribed_users.each do |user|
      crossings_by_metric.each do |metric_id, snapshot_info|
        all_user_crossings[user.id][metric_id] = snapshot_info
      end
    end
  end

  def subscribed_active_users_for_alert(alert_definition)
    contact_ids = GrdaWarehouse::ContactAlertSubscription.
      active.
      where(alert_definition_id: alert_definition.id).
      pluck(:contact_id)

    return [] if contact_ids.empty?

    GrdaWarehouse::Contact::User.
      where(id: contact_ids).
      preload(:user).
      filter_map { |contact| contact.user if contact.user&.active? }.
      index_by(&:email).
      values
  end

  def priority
    10
  end
end
