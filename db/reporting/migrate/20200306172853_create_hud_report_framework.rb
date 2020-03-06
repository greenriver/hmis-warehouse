class CreateHudReportFramework < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_instances do |t|
      t.references :user
      t.string :name

      t.timestamps
    end

    create_table :hud_report_cells do |t|
      t.references :report_instance
      t.string :question
      t.string :cell_name

      t.timestamps
    end

    create_table :hud_universe_members do |t|
      t.references :report_cell
      t.references :universe_membership, polymorphic: true, index: { name: :index_universe_type_and_id }

      t.timestamp
    end
  end
end
