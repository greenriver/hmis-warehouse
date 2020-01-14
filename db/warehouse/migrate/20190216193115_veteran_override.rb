class VeteranOverride < ActiveRecord::Migration[4.2]
  def change
    add_column :Client, :verified_veteran_status, :string
  end
end
