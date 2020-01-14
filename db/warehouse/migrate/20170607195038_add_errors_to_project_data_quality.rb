class AddErrorsToProjectDataQuality < ActiveRecord::Migration[4.2]
  def change
    add_column :project_data_quality, :processing_errors, :text
  end
end
