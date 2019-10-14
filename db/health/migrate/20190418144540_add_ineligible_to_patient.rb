class AddIneligibleToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :ineligible, :date
  end
end
