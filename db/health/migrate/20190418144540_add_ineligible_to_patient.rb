class AddIneligibleToPatient < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :ineligible, :date
  end
end
