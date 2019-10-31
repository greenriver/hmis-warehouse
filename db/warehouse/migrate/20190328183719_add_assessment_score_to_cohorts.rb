class AddAssessmentScoreToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :assessment_score, :integer
  end
end
