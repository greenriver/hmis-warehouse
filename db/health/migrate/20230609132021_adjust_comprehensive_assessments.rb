class AdjustComprehensiveAssessments < ActiveRecord::Migration[6.1]
  def change
    add_column :hca_assessments, :care_goals, :string
    # Small dataset, so this is not expensive
    safety_assured { change_column :hca_assessments, :accessibility_equipment, 'jsonb USING accessibility_equipment::jsonb' }
  end
end
