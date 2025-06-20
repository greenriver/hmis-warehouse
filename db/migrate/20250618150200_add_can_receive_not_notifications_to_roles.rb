
###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
class AddCanReceiveNotNotificationsToRoles < ActiveRecord::Migration[7.1]
  def change
    add_column :roles, :can_receive_cohort_note_notifications, :boolean, default: false

    # Keep consistency with existing data
    Role.where(can_view_clients: true).update_all(can_receive_cohort_note_notifications: true)
  end
end