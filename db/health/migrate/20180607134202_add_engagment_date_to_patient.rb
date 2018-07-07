class AddEngagmentDateToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :engagement_date, :date
  end
end
