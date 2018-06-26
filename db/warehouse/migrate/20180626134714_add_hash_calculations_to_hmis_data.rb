class AddHashCalculationsToHmisData < ActiveRecord::Migration
  def change
    GrdaWarehouse::Hud.models_by_hud_filename.values.map(&:table_name).each do |table|
      add_column table, :source_hash, :string
    end
  end
end
