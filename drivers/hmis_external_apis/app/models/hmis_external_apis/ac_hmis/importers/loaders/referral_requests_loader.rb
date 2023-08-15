###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class ReferralRequestsLoader < SingleFileLoader
    def filename
      'ReferralRequests.csv'
    end

    def perform
      records = build_records
      if clobber
        # destroy existing records and re-import
        model_class.where(project_id: project_scope.select(:id)).destroy_all if clobber
        model_class.import(records, validate: false, batch_size: 1_000)
      end
      ar_import(
        model_class,
        records,
        on_duplicate_key_update: {
          conflict_target: :identifier,
          columns: records[0].keys,
        },
      )
    end

    protected

    def supports_upsert?
      true
    end

    def project_scope
      Hmis::Hud::Project.where(data_source: data_source)
    end

    def model_class
      HmisExternalApis::AcHmis::ReferralRequest
    end

    def build_records
      projects_by_id = project_scope
        .pluck(:project_id, :id)
        .to_h
      unit_types_by_mper = Hmis::UnitType
        .joins(:mper_id)
        .pluck('external_ids.value', :id)
        .to_h

      rows.map do |row|
        {
          identifier: row_value(row, field: 'REFERRAL_REQUEST_ID'),
          project_id: projects_by_id.fetch(row_value(row, field: 'PROGRAM_ID')),
          unit_type_id: unit_types_by_mper.fetch(row_value(row, field: 'UNIT_TYPE_ID')),
          requested_on: parse_date(row_value(row, field: 'REQUESTED_ON')),
          needed_by: parse_date(row_value(row, field: 'NEEDED_BY')),
          requestor_name: row_value(row, field: 'REQUESTOR_NAME', required: false),
          requestor_phone: row_value(row, field: 'REQUESTOR_PHONE', required: false),
          requestor_email: row_value(row, field: 'REQUESTOR_EMAIL', required: false),
        }
      end
    end
  end
end
