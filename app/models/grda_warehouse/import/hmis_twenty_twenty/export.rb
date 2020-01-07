###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HmisTwentyTwenty
  class Export < GrdaWarehouse::Hud::Export
    include ::Import::HmisTwentyTwenty::Shared
    self.hud_key = :ExportID
    setup_hud_column_access( GrdaWarehouse::Hud::Export.hud_csv_headers(version: '2020') )

    validates_presence_of :ExportStartDate, :ExportEndDate, :ExportID, :data_source_id, :ExportDate

    def import!
      @existing = self.class.find_by(ExportID: export_id, data_source_id: data_source_id)
      if @existing.present?
        @existing.update_attributes(attributes.slice(*hud_csv_headers.map(&:to_s)))
        # Include any changed max date
        @existing.update_attributes(effective_export_end_date: effective_export_end_date)
      else
        save
      end
    end

    def self.load_from_csv(file_path: , data_source_id: )
      new CSV.read(
        "#{file_path}/#{data_source_id}/#{file_name}",
        headers: self.hud_csv_headers.map(&:to_s)
      ).drop(1).first.to_h.
      merge({file_path: file_path, data_source_id: data_source_id})
    end

    def self.file_name
      'Export.csv'
    end
  end
end