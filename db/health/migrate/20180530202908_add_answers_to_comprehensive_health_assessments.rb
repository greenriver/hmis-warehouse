class AddAnswersToComprehensiveHealthAssessments < ActiveRecord::Migration
  def change
    add_column :comprehensive_health_assessments, :answers, :json
  end
end
