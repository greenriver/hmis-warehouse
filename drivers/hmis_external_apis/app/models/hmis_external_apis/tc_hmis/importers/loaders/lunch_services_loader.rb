###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class LunchServicesLoader < MealsServicesLoader
    def read_rows
      @reader.rows(filename: filename, header_row_number: 4, field_id_row_number: nil, sheet_number: 0).to_a
    end

    def row_touchpoint(row)
      row.field_value('TouchPoint Name_317')
    end

    def row_response_id(row)
      row.field_value('Response ID_317')
    end

    def row_date_provided(row)
      parse_date(row.field_value('Date taken new format'))
    end

    def service_type_name
      '1A-SA Lunch'
    end
  end
end
