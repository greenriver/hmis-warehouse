class AddDeidentifiedColumnToUploads < ActiveRecord::Migration[4.2]
  def change
    add_column :uploads, :deidentified, :boolean, default: false
  end
end
