class CreateAnalyticsClientFiles < ActiveRecord::Migration[7.0]
  def change
    add_column :files, :url, :string

    create_view "analytics.client_files"
    create_view "analytics.file_tags"
  end
end
