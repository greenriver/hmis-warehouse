class AddCompletedAtToComprehensiveHealthAssessments < ActiveRecord::Migration
  def change
    add_column :comprehensive_health_assessments, :completed_at, :datetime
  end
end
