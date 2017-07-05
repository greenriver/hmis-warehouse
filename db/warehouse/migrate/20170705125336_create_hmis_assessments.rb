class CreateHmisAssessments < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? :hmis_assessments
      drop_table :hmis_assessments {}
    end
    create_table :hmis_assessments do |t|
      t.integer :assessment_id, null: false, index: true
      t.integer :site_id, null: false, index: true
      t.string :site_name
      t.string :name, null: false
      t.boolean :fetch, default: false, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_fetched_at
      t.integer :data_source_id, null: false, index: true
    end
    if ActiveRecord::Base.connection.table_exists? :hmis_answers
      drop_table :hmis_answers {}
    end
    if ActiveRecord::Base.connection.table_exists? :hmis_questions
      drop_table :hmis_questions {}
    end
  end
end


