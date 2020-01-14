class AddCompletedAtToComprehensiveHealthAssessments < ActiveRecord::Migration[4.2]
  def change
    add_column :comprehensive_health_assessments, :completed_at, :datetime
  end
end
