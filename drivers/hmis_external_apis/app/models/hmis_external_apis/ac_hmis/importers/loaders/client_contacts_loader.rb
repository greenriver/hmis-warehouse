###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ClientContactsLoader < SingleFileLoader
    def filename
      'ClientContacts.csv'
    end

    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all if clobber
      ar_import(model_class, records.compact)
    end

    protected

    def build_records
      rows.map do |row|
        value = phone_value(row)
        next unless value

        attrs = {
          ContactPointID: Hmis::Hud::Base.generate_uuid,
          UserID: user_id_value(row),
          PersonalID: row_value(row, field: 'PersonalID'),
          use: use_value(row),
          system: row_value(row, field: 'SYSTM').downcase,
          notes: row_value(row, field: 'NOTES', required: false),
          value: value,
          # these fields should be required but are sometimes missing or unparsable
          DateCreated: parse_date(row_value(row, field: 'DateCreated', required: false)),
          DateUpdated: parse_date(row_value(row, field: 'DateUpdated', required: false)),
        }
        default_attrs.merge(attrs)
      end
    end

    PHONE_TYPE_MAP = {
      'cell' => 'mobile',
      'home' => 'home',
      'work' => 'work',
    }.freeze

    def phone_value(row)
      value = row_value(row, field: 'VALUE')
      return unless value

      # remove non-numeric chars
      value.gsub!(/[^0-9]/, '')
      # skip if all-zeros
      return if value =~ /\A0+\z/

      value
    end

    def use_value(row)
      PHONE_TYPE_MAP[row_value(row, field: 'PHONE_TYPE').downcase]
    end

    def model_class
      Hmis::Hud::CustomClientContactPoint
    end

    # This file has a different date time format
    # M/D/YYYY HH:MM
    DATE_TIME_FMT = '%m/%d/%Y %H:%M'.freeze
    def valid_date?(str)
      str =~ /^\d{1,2}\/\d{1,2}\/\d{4} \d{1,2}:\d{2}$/
    end

    def user_id_value(row)
      # due to missing quotes in CSV, field may be invalid
      value = row_value(row, field: 'UserID', required: false)
      value && value =~ /\A0-9A-Z\z/ ? value : system_user_id
    end

    def parse_date(str)
      # due to missing quotes in CSV, field may be invalid
      return today unless valid_date?(str)

      DateTime.strptime(str, DATE_TIME_FMT)
    end

  end
end
