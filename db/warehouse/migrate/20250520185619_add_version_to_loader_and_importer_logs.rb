# frozen_string_literal: true

class AddVersionToLoaderAndImporterLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_csv_loader_logs, :version, :string
    add_column :hmis_csv_importer_logs, :version, :string
  end
end
