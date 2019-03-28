class AddAssessmentScoreToCohorts < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :assessment_score, :integer
  end
end
