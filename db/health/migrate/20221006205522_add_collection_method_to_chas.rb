class AddCollectionMethodToChas < ActiveRecord::Migration[6.1]
  def change
    add_column :comprehensive_health_assessments, :collection_method, :string
  end
end
