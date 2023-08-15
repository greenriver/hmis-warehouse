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
          UserID: row_value(row, field: 'UserID', required: false) || system_user_id,
          PersonalID: row_value(row, field: 'PersonalID'),
          use: use_value(row),
          system: row_value(row, field: 'SYSTM').downcase,
          notes: row_value(row, field: 'NOTES', required: false),
          value: value,
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
  end
end
