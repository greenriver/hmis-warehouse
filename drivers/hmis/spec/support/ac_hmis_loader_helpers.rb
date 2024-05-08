###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AcHmisLoaderHelpers
  def self.included(base)
    base.before(:each) do
      skip 'Skipping all tests in this file'
    end
  end

  def csv_reader(...)
    HmisExternalApis::AcHmis::Importers::Loaders::CsvReader.new(...)
  end

  def with_csv_files(file_data)
    Dir.mktmpdir do |dir|
      file_data.each do |filename, rows|
        CSV.open("#{dir}/#{filename}", 'w', write_headers: true, headers: rows.first.keys) do |csv|
          rows.each { |row| csv << row.values.map(&:presence) }
        end
      end
      yield(dir)
    end
  end

  def run_cde_import(csv_files:, clobber:)
    with_csv_files(csv_files) do |dir|
      importer = HmisExternalApis::AcHmis::Importers::CustomDataElementsImporter.new(dir: dir, clobber: clobber)
      importer.run!
    end
  end
end
