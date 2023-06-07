class CreateCaAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :ca_assessments do |t|
      t.references :patient
      t.references :instrument, polymorphic: true

      t.timestamps
    end
  end
end
