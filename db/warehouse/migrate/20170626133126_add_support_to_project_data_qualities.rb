class AddSupportToProjectDataQualities < ActiveRecord::Migration
  def change
    add_column :project_data_quality, :support, :json
  end
end
