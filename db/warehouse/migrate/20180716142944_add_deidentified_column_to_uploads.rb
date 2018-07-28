class AddDeidentifiedColumnToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :deidentified, :boolean, default: false
  end
end
