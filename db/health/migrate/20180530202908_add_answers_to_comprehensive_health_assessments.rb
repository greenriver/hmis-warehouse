class AddAnswersToComprehensiveHealthAssessments < ActiveRecord::Migration[4.2]
  def change
    add_column :comprehensive_health_assessments, :answers, :json
  end
end
