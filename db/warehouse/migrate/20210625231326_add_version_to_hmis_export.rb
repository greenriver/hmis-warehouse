class AddVersionToHmisExport < ActiveRecord::Migration[5.2]
  def change
    add_column :exports, :version, :string
  end
end
