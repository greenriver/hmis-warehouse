###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class MealsServicesLoader < BaseLoader
    def filename
      'SA Meal export report.xlsx'
    end

    def runnable?
      reader.file_present?(filename)
    end

    def row_service_id(row)
      "eto-#{service_type_name}-#{row_response_id(row)}".downcase.gsub(/[^a-z0-9]/, '-')
    end

    def row_response_id(_row)
      raise
    end

    def service_type_name(_row)
      raise
    end

    def row_date_provided(_row)
      raise
    end

    def row_touchpoint(_row)
      raise
    end

    def row_personal_id(row)
      normalize_uuid(row.field_value('Participant Enterprise Identifier'))
    end

    def row_enrollment_id(row)
      # this doesn't exist in the sheet, it's extrapolated
      row.field_value('Unique Enrollment Identifier')
    end

    def perform
      rows = read_rows
      clobber_records(rows) if clobber
      extrapolate_missing_enrollment_ids(rows, enrollment_id_field: 'Unique Enrollment Identifier')
      process_rows(rows)
    end

    def process_rows(rows)
      service_type = create_service_type
      expected = 0
      actual = 0

      values = []
      rows.each do |row|
        expected += 1
        service_id = row_service_id(row)
        next unless service_id

        personal_id = row_personal_id(row)
        enrollment_id = row_enrollment_id(row)
        date_provided = row_date_provided(row)

        if !(personal_id && enrollment_id && date_provided)
          log_info("missing required fields #{[personal_id, enrollment_id, date_provided]} in #{row.context}")
          next
        end

        touchpoint = row_touchpoint(row)
        if touchpoint != service_type_name
          log_info("wrong touch point \"#{touchpoint}\" in #{row.context}")
          next
        end

        actual += 1
        values << {
          CustomServiceID: service_id,
          EnrollmentID: enrollment_id,
          PersonalID: personal_id,
          DateProvided: date_provided,
          UserID: system_hud_user.id,
          data_source_id: data_source.id,
          custom_service_type_id: service_type.id,
          service_name: service_type,
          DateCreated: today,
          DateUpdated: today,
          FAAmount: nil,
          FAStartDate: nil,
          FAEndDate: nil,
        }
      end
      log_processed_result(name: 'custom services', expected: expected, actual: actual)
      ar_import(service_class, values)
    end

    def create_service_type
      Hmis::Hud::CustomServiceType.where(data_source: data_source).where(name: service_type_name).first_or_create! do |st|
        st.UserID = system_hud_user.id
        st.custom_service_category_id = placeholder_service_category.id
      end
    end

    def clobber_records(rows)
      service_type = create_service_type
      service_ids = rows.map { |row| row_service_id(row) }
      service_class.where(data_source: data_source).
        where(CustomServiceID: service_ids.compact).
        where(custom_service_type_id: service_type.id).
        delete_all
    end

    def service_class
      Hmis::Hud::CustomService
    end
  end
end
