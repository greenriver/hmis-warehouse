class AddCasUrlConfig < ActiveRecord::Migration
  def change
    add_column :configs, :cas_url, :string, default: 'https://cas.boston.gov'
  end
end
