class AddSentToQualifyingActivity < ActiveRecord::Migration
  def change
    add_column :qualifying_activities, :sent_at, :datetime
  end
end
