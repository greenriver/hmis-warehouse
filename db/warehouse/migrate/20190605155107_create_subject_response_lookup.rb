class CreateSubjectResponseLookup < ActiveRecord::Migration
  def change
    create_table :eto_subject_response_lookups do |t|
      t.references :data_source, null: false
      t.integer :subject_id, null: false, index: true
      t.integer :response_id, null: false
    end
  end
end
