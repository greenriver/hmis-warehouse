class SetDataSourceSourceIds < ActiveRecord::Migration
  def up
    # Pre-populate source_id with most recent SourceID from the export
    GrdaWarehouse::Hud::Export.select(:SourceID, :data_source_id, :ExportDate).order(ExportDate: :desc).distinct.each do |export|
      if export.SourceID.present? && export.data_source.source_id.blank?
        export.data_source.update(source_id: export.SourceID)
      end
    end
  end
end
