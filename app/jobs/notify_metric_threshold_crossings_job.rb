###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Sends emails when metric thresholds are crossed. Invoked after threshold collection (e.g. by
# CsvImportMonitorCollector). Recipients differ by alert type:
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
      # Get threshold crossings grouped by alert code
      crossings_by_alert = GrdaWarehouse::Monitoring::MetricDefinition.
        active.
        threshold_crossings_for_alerts(calculation_date)

      return if crossings_by_alert.empty?

      # For each alert code, send notifications to subscribed users
      crossings_by_alert.each do |alert_code, crossings_by_metric|
        # CSV import alerts use per-monitor NotificationConfiguration; others use ContactAlertSubscription
        if alert_code == CSV_IMPORT_ALERT_CODE
          notify_csv_import_crossings(crossings_by_metric, calculation_date)
        else
          notify_contact_subscribers(alert_code, crossings_by_metric, calculation_date)
        end
      end
    end
  end

  private

  # CSV import: recipients come from NotificationConfiguration on each ImportCsvMonitor.
  # Users only receive crossings for monitors they're subscribed to.
  def notify_csv_import_crossings(crossings_by_metric, calculation_date)
    return if crossings_by_metric.empty?
    return unless defined?(GrdaWarehouse::ImportCsvMonitor)

    # Build user_id => { metric_id => { display_name:, data:, ... } } with only crossings for monitors
    # that each user is subscribed to
    user_crossings = build_csv_import_user_crossings(crossings_by_metric)

    user_crossings.each do |user_id, crossings|
      user = User.find_by(id: user_id)
      next unless user&.active?

      NotifyUser.metric_threshold_crossed(
        user_id: user.id,
        alert_code: CSV_IMPORT_ALERT_CODE,
        crossings: crossings,
        calculation_date: calculation_date,
      ).deliver_now
    end
  end

  # Maps raw crossings (grouped by metric) to user-centric crossings. For each crossing, finds the
  # ImportCsvMonitor (data_source + csv_file), collects users subscribed via NotificationConfiguration,
  # and adds the crossing to each user's hash. Users only see crossings for monitors they follow.
  def build_csv_import_user_crossings(crossings_by_metric)
    user_crossings = Hash.new { |h, k| h[k] = {} }

    crossings_by_metric.each do |metric_id, snapshot_info|
      metric_def = GrdaWarehouse::Monitoring::MetricDefinition.find_by(id: metric_id)
      next unless metric_def&.subtype.present?

      csv_file_name = metric_def.subtype
      data = snapshot_info[:data] || []

      data.each do |crossing|
        entity_id = crossing[:entity_id] # data_source_id for csv_import
        monitor = GrdaWarehouse::ImportCsvMonitor.find_by(
          data_source_id: entity_id,
          csv_file_name: csv_file_name,
          active: true,
        )
        next unless monitor

        user_ids = GrdaWarehouse::NotificationConfiguration.
          where(
            source: monitor,
            notification_slug: GrdaWarehouse::ImportCsvMonitor::NOTIFICATION_SLUG,
            active: true,
          ).
          pluck(:user_id).
          compact.
          uniq

        user_ids.each do |user_id|
          user_crossings[user_id][metric_id] ||= {
            display_name: snapshot_info[:display_name],
            data: [],
            total_count: 0,
            truncated: snapshot_info[:truncated],
            entity_label: metric_def.entity_label,
          }
          user_crossings[user_id][metric_id][:data] << crossing
          user_crossings[user_id][metric_id][:total_count] += 1
        end
      end
    end

    user_crossings
  end

  # Non-CSV alerts (e.g. client metrics): recipients come from ContactAlertSubscription on the
  # AlertDefinition. All subscribed users receive the full crossings_by_metric (no per-user filtering).
  def notify_contact_subscribers(alert_code, crossings_by_metric, calculation_date)
    alert_definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
    return unless alert_definition

    # Get user IDs from contact_alert_subscriptions (warehouse database)
    contact_ids = GrdaWarehouse::ContactAlertSubscription.
      active.
      where(alert_definition_id: alert_definition.id).
      pluck(:contact_id)

    return if contact_ids.empty?

    # Load Contact::User records (warehouse database) - load into memory for deduplication
    subscribed_contacts = GrdaWarehouse::Contact::User.
      where(id: contact_ids).
      preload(:user).
      to_a

    return if subscribed_contacts.empty?

    # Filter to contacts with active users and deduplicate by email
    subscribed_users = subscribed_contacts.
      select { |contact| contact.user&.active? }.
      map(&:user).
      compact.
      index_by(&:email).
      values

    return if subscribed_users.empty?

    # Send notification to each unique subscribed user
    subscribed_users.each do |user|
      NotifyUser.metric_threshold_crossed(
        user_id: user.id,
        alert_code: alert_code,
        crossings: crossings_by_metric,
        calculation_date: calculation_date,
      ).deliver_now
    end
  end

  def priority
    10
  end
end
