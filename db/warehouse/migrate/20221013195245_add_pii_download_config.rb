class AddPiiDownloadConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :include_pii_in_detail_downloads, :boolean, default: true
  end
end
