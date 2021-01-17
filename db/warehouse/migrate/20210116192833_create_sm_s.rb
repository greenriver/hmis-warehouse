class CreateSmS < ActiveRecord::Migration[5.2]
  def change
    create_table :text_message_topics do |t|
      t.string :arn
      t.string :title, index: true, unique: true
      t.boolean :active_topic, default: :true, null: false
      t.timestamps index: true, null: false
      t.datetime :deleted_at
    end
    create_table :text_message_topic_subscribers do |t|
      t.references :topic
      t.timestamp :subscribed_at
      t.timestamp :unsubscribed_at
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.timestamps index: true, null: false
      t.datetime :deleted_at
    end
    create_table :text_message_messages do |t|
      t.references :topic
      t.references :subscriber
      t.date :send_on_or_after
      t.datetime :sent_at
      t.string :sent_to
      t.string :content, length: 160
      t.timestamps index: true, null: false
      t.datetime :deleted_at
    end
  end
end
