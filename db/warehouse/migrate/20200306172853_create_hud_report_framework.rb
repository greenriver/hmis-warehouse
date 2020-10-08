class CreateHudReportFramework < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_instances do |t|
      t.references :user
      t.string :coc_code
      t.string :report_name
      t.date :start_date
      t.date :end_date
      t.json :options

      t.string :state
      t.timestamp :started_at
      t.timestamp :completed_at

      t.timestamps
    end

    create_table :hud_report_cells do |t|
      t.references :report_instance
      t.string :question, null: false
      t.string :cell_name
      t.boolean :universe, default: false
      t.json :metadata

      t.timestamps
    end

    create_table :hud_report_universe_members do |t|
      t.references :report_cell
      t.references :universe_membership, polymorphic: true, index: { name: :index_universe_type_and_id }

      t.references :client

      t.string :first_name
      t.string :last_name

      t.timestamp
    end
  end
end
