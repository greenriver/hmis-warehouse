###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class Export < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::Export
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2020_exports'

    attr_accessor :file_path

    def self.load_from_csv(file_path:, data_source_id:)
      new CSV.read(
        File.join(file_path, data_source_id.to_s, file_name),
        headers: hud_csv_headers.map(&:to_s),
      ).drop(1).first.to_h.
        merge({ file_path: file_path, data_source_id: data_source_id })
    end

    def self.file_name
      'Export.csv'
    end
  end
end
