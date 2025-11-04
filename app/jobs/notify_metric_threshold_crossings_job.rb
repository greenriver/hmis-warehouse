###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class NotifyMetricThresholdCrossingsJob < BaseJob
  queue_as ENV.fetch('DJ_DEFAULT_QUEUE_NAME', :default)
  queue_with_priority 10

  def perform(calculation_date = Date.current)
    # Get threshold crossings grouped by alert code
    crossings_by_alert = GrdaWarehouse::Monitoring::MetricDefinition.
      active.
      threshold_crossings_for_alerts(calculation_date)

    return if crossings_by_alert.empty?

    # For each alert code, send notifications to subscribed users
    crossings_by_alert.each do |alert_code, crossings_by_metric|
      # Find the alert definition (warehouse database)
      alert_definition = GrdaWarehouse::AlertDefinition.find_by(code: alert_code)
      next unless alert_definition

      # Get user IDs from contact_alert_subscriptions (warehouse database)
      contact_ids = GrdaWarehouse::ContactAlertSubscription.
        active.
        where(alert_definition_id: alert_definition.id).
        pluck(:contact_id)

      next if contact_ids.empty?

      # Get user IDs from contacts (warehouse database)
      user_ids = GrdaWarehouse::Contact::User.
        where(id: contact_ids).
        pluck(:user_id)

      next if user_ids.empty?

      # Get active users (app database)
      subscribed_users = User.active.where(id: user_ids)

      # Send notification to each subscribed user
      subscribed_users.find_each do |user|
        NotifyUser.metric_threshold_crossed(
          user_id: user.id,
          alert_code: alert_code,
          crossings: crossings_by_metric,
          calculation_date: calculation_date,
        ).deliver_now
      end
    end
  end

  def priority
    10
  end
end
