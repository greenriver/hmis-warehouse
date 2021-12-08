class AddDataSourceToAssessmentLookups < ActiveRecord::Migration[5.2]
  def change
    add_column :assessment_answer_lookups, :data_source_id, :integer
  end
end
