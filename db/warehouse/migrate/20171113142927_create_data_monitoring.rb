class CreateDataMonitoring < ActiveRecord::Migration
  def change
    create_table :data_monitorings do |t|
      t.references :client, null: false
      t.date :census
      t.date :calculated_on
      t.date :calculate_after
      t.float :value
      t.float :change
      t.integer :iteration
      t.integer :of_iterations
      t.string :type
    end
  end
end
