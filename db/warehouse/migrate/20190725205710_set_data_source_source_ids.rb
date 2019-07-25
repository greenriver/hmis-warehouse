class SetDataSourceSourceIds < ActiveRecord::Migration
  def up
    GrdaWarehouse::Hud::Export.select(:SourceID, :data_source_id).distinct.each do |export|
      if export.SourceID.present?
        export.data_source.update(source_id: export.SourceID)
      end
    end
  end
end
