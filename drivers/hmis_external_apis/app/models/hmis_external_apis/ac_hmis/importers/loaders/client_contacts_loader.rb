###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ClientContactsLoader < BaseLoader
    def perform(rows:)
      records = build_records(rows)
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all
      model_class.import(records, validate: false, batch_size: 1_000)
    end

    protected

    def build_records(rows)
      rows.map do |row|
        attrs = {
          ContactPointID: Hmis::Hud::Base.generate_uuid,
          UserID: row_value(row, field: 'UserID') || system_user_id,
          PersonalID: row_value(row, field: 'PersonalID'),
          use: use_value(row),
          system: row_value(row, field: 'SYSTM').downcase,
          notes: row_value(row, field: 'NOTES'),
          value: row_value(row, field: 'VALUE'),
          DateCreated: row_value(row, field: 'DateCreated'),
          DateUpdated: row_value(row, field: 'DateUpdated'),
        }
        default_attrs.merge(attrs)
      end
    end

    PHONE_TYPE_MAP = {
      'cell' => 'mobile',
      'home' => 'home',
      'work' => 'work',
    }.freeze

    def use_value(row)
      PHONE_TYPE_MAP[row_value(row, field: 'PHONE_TYPE').downcase]
    end

    def model_class
      Hmis::Hud::CustomClientContactPoint
    end
  end
end
