class AdjustGlacierDatatypes < ActiveRecord::Migration
  def change
    change_column :glacier_archives, :size_in_bytes, :integer, limit: 8
  end
end
