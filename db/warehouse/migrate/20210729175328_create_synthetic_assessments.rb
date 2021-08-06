class CreateSyntheticAssessments < ActiveRecord::Migration[5.2]
  def change
    create_table :synthetic_assessments do |t|
      t.references :enrollment
      t.references :client
      t.string :type
      t.references :source, polymorphic: true
      t.references :hud_assessment

      t.timestamps
    end
  end
end
