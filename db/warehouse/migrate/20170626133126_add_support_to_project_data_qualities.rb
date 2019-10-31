class AddSupportToProjectDataQualities < ActiveRecord::Migration[4.2]
  def change
    add_column :project_data_quality, :support, :json
  end
end
