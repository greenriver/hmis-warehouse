###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
        dimensions = contents[:dimensions]
        table = create_table(**dimensions)
        contents.each do |tab_name, cells|
          next if tab_name == :dimensions

          fixed_tab_name = tab_name.ljust(28).truncate(28, omission: '') # Source XLSX has a fixed size for the tabs
          sheet = xlsx.sheet(fixed_tab_name)
          cells.each do |cell_name, destination|
            col, row = parse_cell_name(cell_name)
            val = sheet.cell(col, row)

            col, row = parse_cell_name(destination)
            row -= 1 unless contents[:dimensions][:add_labels]
            table[row][col] = val
          end
        end
        CSV.open(File.join(@dir, csv_name), 'wb') do |csv|
          table.each do |row|
            csv << row.values
          end
        end
      end
    end

    def create_table(rows:, column:, add_labels: false)
      column_count = ('A'..'Z').find_index(column)
      column_count += 1 if add_labels # M1 of the SPM lacks space for labels in the table
      rows += 1 if add_labels
      [].tap do |table|
        rows.times do |_|
          row = ('A'..column).zip(Array.new(column_count)).to_h
          row = { '' => nil }.merge(row) if add_labels
          table << row
        end
      end
    end

    def parse_cell_name(name)
      col = /[A-Z]+/.match(name)[0]
      row = /[0-9]+/.match(name)[0].to_i

      [col, row]
    end

    def transforms
      {
        '1a.csv' => {
          dimensions: { rows: 2, column: 'H', add_labels: true },
          '1a.1 Length of Time Persons Remain Homeless - EXCLUDING 3.917 data - Shelters and Safe Havens' => {
            B3: :B1,
            C3: :D1,
            D3: :G1,
          },
          '1a.2 Length of Time Persons Remain Homeless - EXCLUDING 3.917 data - Shelters, Safe Havens, and Transitional Housing' => {
            B3: :B2,
            C3: :D2,
            D3: :G2,
          },
        },
        '1b.csv' => {
          dimensions: { rows: 2, column: 'H', add_labels: true },
          '1b.1 Length of Time Persons Remain Homeless - INCLUDING 3.917 data - Shelters, Safe Havens, and Permanent Housing' => {
            B3: :B1,
            C3: :D1,
            D3: :G1,
          },
          '1b.2 Length of Time Persons Remain Homeless - INCLUDING 3.917 data - Shelters, Safe Havens, Transitional Housing, and Permanent Housing' => {
            B3: :B2,
            C3: :D2,
            D3: :G2,
          },
        },
        '2.csv' => {
          dimensions: { rows: 7, column: 'J' },
          '2a. The Extent to which Persons who Exit Homelessness to Permanent Housing Destinations Return to Homelessness' => {
            C3: :B2,
            C4: :B3,
            C5: :B4,
            C6: :B5,
            C7: :B6,
            C8: :B7,

            D3: :C2,
            D4: :C3,
            D5: :C4,
            D6: :C5,
            D7: :C6,
            D8: :C7,

            E3: :D2,
            E4: :D3,
            E5: :D4,
            E6: :D5,
            E7: :D6,
            E8: :D7,

            F3: :E2,
            F4: :E3,
            F5: :E4,
            F6: :E5,
            F7: :E6,
            F8: :E7,

            G3: :F2,
            G4: :F3,
            G5: :F4,
            G6: :F5,
            G7: :F6,
            G8: :F7,

            H3: :G2,
            H4: :G3,
            H5: :G4,
            H6: :G5,
            H7: :G6,
            H8: :G7,

            I3: :H2,
            I4: :H3,
            I5: :H4,
            I6: :H5,
            I7: :H6,
            I8: :H7,

            J3: :I2,
            J4: :I3,
            J5: :I4,
            J6: :I5,
            J7: :I6,
            J8: :I7,

            K3: :J2,
            K4: :J3,
            K5: :J4,
            K6: :J5,
            K7: :J6,
            K8: :J7,
          },
        },
        # 3.1.csv is manually entered per the spec, and not in the test kit (v2.0)
        '3.2.csv' => {
          dimensions: { rows: 5, column: 'D' },
          '3.2 Change in annual counts of sheltered homeless persons in HMIS' => {
            C3: :C2,
            C4: :C3,
            C5: :C4,
            C6: :C5,
          },
        },
        '4.1.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.1 Change in earned income for adult system stayers during the reporting period' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '4.2.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.2 Change in non-employment cash income for adult system stayers during the reporting period' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '4.3.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.3 Change in total income for adult system stayers during the reporting period' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '4.4.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.4 Change in earned income for adult system leavers' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '4.5.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.5 Change in non-employment income for adult system leavers' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '4.6.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '4.6 Change in total income for adult system leavers.' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '5.1.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '5.1 Change in active persons in ES, SH, and TH projects with no prior enrollments in HMIS' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        '5.2.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '5.2 Change in the number of persons from ES, SH, TH, and PH projects with no prior enrollments in HMIS' => {
            C2: :C2,
            C3: :C3,
            C4: :C4,
          },
        },
        # Measure 6 is not in the test kit (v2.0) as no CoC are approved for the population
        '7a.1.csv' => {
          dimensions: { rows: 5, column: 'D' },
          '7a.1 Change in exits to permanent housing destinations - Street Outreach' => {
            C3: :C2,
            C4: :C3,
            C5: :C4,
            # The test kit doesn't include C5 (% Successful exits)
          },
        },
        '7b.1.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '7b.1 Change in exits to permanent housing destinations - ES, SH, TH, PH-RRH, and PH who exited without moving in' => {
            C3: :C2,
            C4: :C3,
            D4: :C4,
          },
        },
        '7b.2.csv' => {
          dimensions: { rows: 4, column: 'D' },
          '7b.2 Change in exit to or retention of permanent housing - all PH except PH-RRH' => {
            C3: :C2,
            C4: :C3,
            D4: :C4,
          },
        },
      }.freeze
    end
  end
end
