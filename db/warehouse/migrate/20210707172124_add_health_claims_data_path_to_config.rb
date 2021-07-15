class AddHealthClaimsDataPathToConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :health_claims_data_path, :string
  end
end
