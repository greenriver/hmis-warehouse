class AddEngagmentDateToPatient < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :engagement_date, :date
  end
end
