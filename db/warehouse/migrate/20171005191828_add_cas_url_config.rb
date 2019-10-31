class AddCasUrlConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :cas_url, :string, default: 'https://cas.boston.gov'
  end
end
