class VeteranOverride < ActiveRecord::Migration
  def change
    add_column :Client, :verified_veteran_status, :string
  end
end
