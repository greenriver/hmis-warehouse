###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class BreakfastServicesLoader < MealsServicesLoader
    def read_rows
      @reader.rows(filename: filename, header_row_number: 2, field_id_row_number: nil, sheet_number: 1).to_a
    end

    def row_touchpoint(row)
      row.field_value('TouchPoint Name_318')
    end

    def row_response_id(row)
      row.field_value('Response ID_318')
    end

    def row_date_provided(row)
      parse_date(row.field_value('Date taken new format (1)'))
    end

    def service_type_name
      '1A-SA Breakfast'
    end
  end
end
