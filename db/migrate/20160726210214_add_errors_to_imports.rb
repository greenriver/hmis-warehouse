class AddErrorsToImports < ActiveRecord::Migration[4.2]
  def change
    add_column :imports, :import_errors, :json
  end
end
