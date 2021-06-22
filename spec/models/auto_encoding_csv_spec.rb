require 'rails_helper'

RSpec.describe AutoEncodingCsv, type: :model do
  REFERENCE_DATA = CSV.read("#{file_fixture_path}/importers/encodings/UTF-8.csv", headers: true)

  encodings = [
    'UTF-8',
    'UTF-8-bom',
    'Windows-1252',
  ].each do |encoding|
    it "Autodetect #{encoding}" do
      path = "#{file_fixture_path}/importers/encodings/#{encoding}.csv"
      # puts path
      # data_a = CSV.read(path, headers: true, encoding: encoding)
      data = AutoEncodingCsv.read(path, headers: true)
      expect(data).to eq(REFERENCE_DATA)
    end
  end
end
