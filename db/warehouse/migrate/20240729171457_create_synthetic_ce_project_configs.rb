class CreateSyntheticCeProjectConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :synthetic_ce_assessment_project_configs do |t|
      t.references :project, null: false
      t.boolean :active, default: false, null: false
      t.integer :assessment_type, null: false
      t.integer :assessment_level, null: false
      t.integer :prioritization_status, null: false
      t.timestamps
    end
  end
end
