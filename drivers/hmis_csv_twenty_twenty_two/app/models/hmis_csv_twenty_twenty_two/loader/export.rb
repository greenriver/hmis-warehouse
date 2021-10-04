###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Loader
  class Export < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HMIS::Structure::Export
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_exports'

    attr_accessor :file_path

    def self.load_from_csv(file_path:, data_source_id:)
      new CSV.parse(
        File.read(File.join(file_path, hud_csv_file_name)).gsub("\r\n", "\n"),
        headers: hud_csv_headers.map(&:to_s),
        liberal_parsing: true,
      ).drop(1).first.to_h.
        merge({ file_path: file_path, data_source_id: data_source_id })
    end
  end
end
