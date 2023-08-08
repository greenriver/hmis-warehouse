###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ClientAddressLoader < BaseLoader
    def perform(rows:)
      records = build_records(rows)
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all
      model_class.import(records, validate: false, batch_size: 1_000)
    end

    protected

    def build_records(rows)
      rows.map do |row|
        default_attrs.merge({
          AddressID: Hmis::Hud::Base.generate_uuid,
          UserID: row_value(row, field: 'UserID') || system_user_id,
          PersonalID: row_value(row, field: 'PersonalID'),
          use: row_value(row, field: 'use'),
          line1: row_value(row, field: 'line1'),
          line2: row_value(row, field: 'line2'),
          city: row_value(row, field: 'city'),
          state: normalize_state(row),
          country: row_value(row, field: 'country'),
          postal_code: normalize_zipcode(row),
          DateCreated: row_value(row, field: 'DateCreated'),
          DateUpdated: row_value(row, field: 'DateUpdated'),
        })
      end
    end

    STATES = ['AK', 'AL', 'AR', 'AS', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'GU', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MP', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VI', 'VT', 'WA', 'WI', 'WV', 'WY'].to_set
    def normalize_state(row)
      value = row_value(row, field: 'state')
      return unless value

      # strip_tags and upcase
      ActionView::Base.full_sanitizer
        .sanitize(value)
        .upcase
        .presence_in(STATES)
    end

    def normalize_zipcode(row)
      [
        row_value(row, field: 'zip'),
        row_value(row, field: 'Zipextension'),
      ].compact.join('-')
    end

    def model_class
      Hmis::Hud::CustomClientAddress
    end
  end
end
