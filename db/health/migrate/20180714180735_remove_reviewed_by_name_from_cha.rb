class RemoveReviewedByNameFromCha < ActiveRecord::Migration[4.2][4.2]
  def change
    remove_column :comprehensive_health_assessments, :reviewed_by_name, :string
  end
end
