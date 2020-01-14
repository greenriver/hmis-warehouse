class AddAssessmentTrigger < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :assessment_trigger, :string
  end
end
