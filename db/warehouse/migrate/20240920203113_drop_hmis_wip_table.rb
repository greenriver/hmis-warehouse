class DropHmisWipTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :hmis_wips
  end
end
