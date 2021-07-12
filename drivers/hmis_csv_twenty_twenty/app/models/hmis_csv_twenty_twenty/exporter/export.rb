###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class Export < GrdaWarehouse::Hud::Export
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    attr_accessor :path

    setup_hud_column_access(GrdaWarehouse::Hud::Export.hud_csv_headers(version: '2020'))

    def initialize(path:)
      super
      @path = path
    end

    def export!
      headers = self.class.hud_csv_headers(version: '2020')
      export_path = File.join(@path, self.class.hud_csv_file_name)
      CSV.open(export_path, 'wb') do |csv|
        csv << headers
        csv << attributes.slice(*headers.map(&:to_s)).values
      end
    end
  end
end
