class AddReviewedByNameToCha < ActiveRecord::Migration
  def change
    add_column :comprehensive_health_assessments, :reviewed_by_name, :string
  end
end
