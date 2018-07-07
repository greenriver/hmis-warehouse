module GrdaWarehouse::Import::HMISFiveOne
  class Export < GrdaWarehouse::Hud::Export
    include ::Import::HMISFiveOne::Shared

    setup_hud_column_access( GrdaWarehouse::Hud::Export.hud_csv_headers(version: '5.1') )

    validates_presence_of :ExportStartDate, :ExportEndDate, :ExportID, :data_source_id, :ExportDate

    def import!
      @existing = self.class.find_by(ExportID: export_id, data_source_id: data_source_id)
      if @existing.present?
        @existing.update_attributes(attributes.slice(*hud_csv_headers.map(&:to_s)))
      else
        save!
      end
    end

    def self.load_from_csv(file_path: , data_source_id: )
      new CSV.read(
        "#{file_path}/#{data_source_id}/#{file_name}",
        headers: true
      ).first.to_h.
      merge({file_path: file_path, data_source_id: data_source_id})
    end

    def self.file_name
      'Export.csv'
    end
  end
end