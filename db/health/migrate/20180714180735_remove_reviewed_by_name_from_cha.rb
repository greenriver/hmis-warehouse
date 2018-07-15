class RemoveReviewedByNameFromCha < ActiveRecord::Migration
  def change
    remove_column :comprehensive_health_assessments, :reviewed_by_name, :string
  end
end
