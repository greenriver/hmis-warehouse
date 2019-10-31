class AddSiteConfigForCasRelease < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :cas_flag_method, :string, default: :manual
  end
end
