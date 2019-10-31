class AddReviewedByNameToCha < ActiveRecord::Migration[4.2]
  def change
    add_column :comprehensive_health_assessments, :reviewed_by_name, :string
  end
end
