###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class Export < GrdaWarehouse::Import::HmisTwentyTwenty::Export
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    attr_accessor :path
    self.hud_key = :ExportID
    setup_hud_column_access(GrdaWarehouse::Hud::Export.hud_csv_headers(version: '2020'))

    def initialize(path:)
      super
      @path = path
    end

    def export!
      export_path = File.join(@path, self.class.file_name)
      CSV.open(export_path, 'wb') do |csv|
        csv << hud_csv_headers
        csv << attributes.slice(*hud_csv_headers.map(&:to_s)).values
      end
    end
  end
end
