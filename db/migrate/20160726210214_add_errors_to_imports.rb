class AddErrorsToImports < ActiveRecord::Migration
  def change
    add_column :imports, :import_errors, :json
  end
end
