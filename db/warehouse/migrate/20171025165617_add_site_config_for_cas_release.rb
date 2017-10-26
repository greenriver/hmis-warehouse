class AddSiteConfigForCasRelease < ActiveRecord::Migration
  def change
    add_column :configs, :cas_flag_method, :string, default: :manual
  end
end
