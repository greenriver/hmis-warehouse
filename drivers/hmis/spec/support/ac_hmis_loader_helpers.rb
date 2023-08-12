###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AcHmisLoaderHelpers
  def csv_reader(...)
    HmisExternalApis::AcHmis::Importers::Loaders::CsvReader.new(...)
  end

  def with_csv_files(file_data)
    Dir.mktmpdir do |dir|
      file_data.each do |filename, rows|
        CSV.open("#{dir}/#{filename}", 'w', write_headers: true, headers: rows.first.keys) do |csv|
          rows.each { |row| csv << row.values}
        end
      end
      yield(dir)
    end
  end
end
