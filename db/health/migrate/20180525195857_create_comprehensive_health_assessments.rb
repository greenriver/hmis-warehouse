class CreateComprehensiveHealthAssessments < ActiveRecord::Migration
  def change
    create_table :comprehensive_health_assessments do |t|
      t.belongs_to :patient, index: true, foreign_key: true
      t.belongs_to :user, index: true
      t.belongs_to :health_file, index: true, foreign_key: true
      t.integer :status, default: 0
      t.belongs_to :reviewed_by, index: true
      t.timestamps
    end
  end
end
