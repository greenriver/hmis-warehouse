###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateGrdaWarehouseMonitoringThresholdNotificationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :grda_warehouse_monitoring_threshold_notification_logs do |t|
      t.bigint :user_id, null: false
      t.bigint :message_id
      t.string :email_type, null: false
      t.datetime :sent_at, null: false
      t.boolean :delivery_failed, null: false, default: false
      t.text :delivery_error
      t.jsonb :details, null: false, default: {}
      t.timestamps
    end

    add_index(
      :grda_warehouse_monitoring_threshold_notification_logs,
      [:user_id, :sent_at],
      order: { sent_at: :desc },
      name: 'idx_threshold_notification_logs_user_sent_at',
    )

    add_index(
      :grda_warehouse_monitoring_threshold_notification_logs,
      :message_id,
      unique: true,
      where: 'message_id IS NOT NULL',
      name: 'idx_threshold_notification_logs_message_id',
    )
  end
end
