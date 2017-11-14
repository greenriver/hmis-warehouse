class CreateDataMonitoring < ActiveRecord::Migration
  def change
    create_table :data_monitorings do |t|
      t.references :client, null: false, index: true
      t.date :census, index: true
      t.date :calculated_on, index: true
      t.date :calculate_after
      t.float :value
      t.float :change
      t.integer :iteration
      t.integer :of_iterations
      t.string :type, index: true
    end
  end
end
