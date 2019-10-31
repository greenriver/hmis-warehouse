class AdjustGlacierDatatypes < ActiveRecord::Migration[4.2]
  def change
    change_column :glacier_archives, :size_in_bytes, :integer, limit: 8
  end
end
