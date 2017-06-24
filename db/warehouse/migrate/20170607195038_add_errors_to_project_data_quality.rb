class AddErrorsToProjectDataQuality < ActiveRecord::Migration
  def change
    add_column :project_data_quality, :processing_errors, :text
  end
end
