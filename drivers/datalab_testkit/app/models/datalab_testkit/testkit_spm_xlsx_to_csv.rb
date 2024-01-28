###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'csv'
module DatalabTestkit
  class TestkitSpmXlsxToCsv
    def initialize(dir)
      @dir = dir
    end

    def convert(filename)
      xlsx = ::Roo::Excelx.new(File.join(@dir, filename))
      transforms.each do |csv_name, contents|
        tab_name = contents[:tab]
        sheet = xlsx.sheet(tab_name)

        CSV.open(File.join(@dir, csv_name), 'wb') do |csv|
          contents[:rows].times do |row_num|
            csv << sheet.row(row_num + 1)
          end
        end
      end
    end

    def transforms
      {
        '1a.csv' => {
          rows: 3,
          tab: 'spm_1a',
        },
        '1b.csv' => {
          rows: 3,
          tab: 'spm_1b',
        },
        '2.csv' => {
          rows: 7,
          tab: 'spm_2',
        },
        '3.csv' => {
          rows: 5,
          tab: 'spm_3',
        },
        '4.1.csv' => {
          rows: 4,
          tab: 'spm_4.1',
        },
        '4.2.csv' => {
          rows: 4,
          tab: 'spm_4.2',
        },
        '4.3.csv' => {
          rows: 4,
          tab: 'spm_4.3',
        },
        '4.4.csv' => {
          rows: 4,
          tab: 'spm_4.4',
        },
        '4.5.csv' => {
          rows: 4,
          tab: 'spm_4.5',
        },
        '4.6.csv' => {
          rows: 4,
          tab: 'spm_4.6',
        },
        '5.1.csv' => {
          rows: 4,
          tab: 'spm_5.1',
        },
        '5.2.csv' => {
          rows: 4,
          tab: 'spm_5.2',
        },
        '7a1.csv' => {
          rows: 5,
          tab: 'spm_7a1',
        },
        '7b1.csv' => {
          rows: 4,
          tab: 'spm_7b1',
        },
        '7b2.csv' => {
          rows: 4,
          tab: 'spm_7b2',
        },
      }.freeze
    end
  end
end
