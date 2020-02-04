class UpdatedCarePlans < ActiveRecord::Migration[5.2]
  def change
    add_column :health_goals, :timeframe, :text
    add_column :careplans, :issues, :text

     create_table :backup_plans do |t|
      t.references :patient

      t.string :description
      t.string :backup_plan
      t.string :person
      t.string :phone
      t.text :address

      t.date :plan_created_on

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
