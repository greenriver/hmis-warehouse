class AddConfigForSendingSmS < ActiveRecord::Migration[5.2]
  def change
    add_column :text_message_topics, :send_hour, :integer
    add_column :health_emergency_vaccinations, :notification_status, :text
    add_column :text_message_messages, :delivery_status, :string
    add_column :text_message_topic_subscribers, :client_id, :integer, index: true
  end
end
