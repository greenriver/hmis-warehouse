class CreateCasCeAssessments < ActiveRecord::Migration[5.2]
  def change
    create_table :cas_ce_assessments do |t|
      t.references :cas_client
      t.references :cas_non_hmis_assessment
      t.references :hmis_client
      t.references :program
      t.date :assessment_date
      t.string :assessment_location
      t.integer :assessment_type
      t.integer :assessment_level
      t.integer :assessment_status
      t.datetime :assessment_created_at
      t.datetime :assessment_updated_at

      t.timestamps
    end

    # NOTE: this table is also added in a different migration/branch
    unless connection.table_exists?(:synthetic_assessments)
      create_table :synthetic_assessments do |t|
        t.references :enrollment
        t.references :client
        t.string :type
        t.references :source, polymorphic: true

        t.timestamps
      end
    end
  end
end
