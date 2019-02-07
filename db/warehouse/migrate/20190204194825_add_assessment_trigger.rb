class AddAssessmentTrigger < ActiveRecord::Migration
  def change
    add_column :cohorts, :assessment_trigger, :string
  end
end
