class CreateSyntheticAssessments < ActiveRecord::Migration[5.2]
  def change
    # NOTE: this table is also added in a different migration/branch
    unless connection.table_exists?(:synthetic_assessments)
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
end
