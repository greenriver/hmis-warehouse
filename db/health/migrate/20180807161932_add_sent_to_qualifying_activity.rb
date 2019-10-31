class AddSentToQualifyingActivity < ActiveRecord::Migration[4.2]
  def change
    add_column :qualifying_activities, :sent_at, :datetime
  end
end
