class AddUserToDataQualityReport < ActiveRecord::Migration
  def change
    add_column :project_data_quality, :requestor_id, :integer
  end
end
