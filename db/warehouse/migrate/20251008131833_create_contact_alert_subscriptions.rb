###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateContactAlertSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_alert_subscriptions do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :alert_definition, null: false, foreign_key: true
      t.boolean :active, default: true, null: false, comment: 'Enable/disable subscription'
      t.timestamps
    end

    add_index(
      :contact_alert_subscriptions,
      [:contact_id, :alert_definition_id],
      unique: true,
      name: 'index_contact_alerts_on_contact_and_definition',
    )
  end
end
