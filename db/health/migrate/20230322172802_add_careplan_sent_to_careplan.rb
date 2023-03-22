class AddCareplanSentToCareplan < ActiveRecord::Migration[6.1]
  def change
    add_column :careplans, :careplan_sent, :boolean
    add_reference :careplans, :careplan_sender
    add_column :careplans, :careplan_sent_on, :date
  end
end
