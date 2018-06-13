class AddReviewedAtToTables < ActiveRecord::Migration
  def change
    add_column :release_forms, :reviewed_at, :datetime
    add_column :release_forms, :reviewer, :string

    add_column :participation_forms, :reviewed_at, :datetime
    add_column :participation_forms, :reviewer, :string

    add_column :comprehensive_health_assessments, :reviewed_at, :datetime
    add_column :comprehensive_health_assessments, :reviewer, :string
  end
end
