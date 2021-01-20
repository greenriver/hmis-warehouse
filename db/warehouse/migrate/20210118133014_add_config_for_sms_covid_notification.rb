class AddConfigForSmsCovidNotification < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :send_sms_for_covid_reminders, :boolean, default: false, null: false
  end
end
