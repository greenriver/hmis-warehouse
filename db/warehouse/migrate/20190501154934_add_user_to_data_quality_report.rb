class AddUserToDataQualityReport < ActiveRecord::Migration[4.2]
  def change
    add_column :project_data_quality, :requestor_id, :integer
  end
end
