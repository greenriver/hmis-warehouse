###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class ClientAddressLoader < SingleFileLoader
    def filename
      'ClientAddress.csv'
    end

    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).destroy_all if clobber
      ar_import(model_class, records)
    end

    protected

    def build_records
      rows.map do |row|
        default_attrs.merge(
          {
            AddressID: Hmis::Hud::Base.generate_uuid,
            UserID: row_value(row, field: 'UserID', required: false) || system_user_id,
            PersonalID: row_value(row, field: 'PersonalID'),
            use: row_value(row, field: 'use'),
            line1: row_value(row, field: 'line1', required: false),
            line2: row_value(row, field: 'line2', required: false),
            city: row_value(row, field: 'city', required: false),
            state: normalize_state(row),
            country: row_value(row, field: 'country', required: false),
            postal_code: normalize_zipcode(row),
            DateCreated: date_created(row),
            DateUpdated: parse_date(row_value(row, field: 'DateUpdated')),
          },
        )
      end
    end

    def date_created(row)
      value = row_value(row, field: 'DateCreated')
      # sometimes we see non-date values here- falling back to the update date in that case
      parse_date(valid_date?(value) ? value : row_value(row, field: 'DateUpdated'))
    end

    STATES = ['AK', 'AL', 'AR', 'AS', 'AZ', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'GU', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MP', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VI', 'VT', 'WA', 'WI', 'WV', 'WY'].to_set
    def normalize_state(row)
      value = row_value(row, field: 'state', required: false)
      return unless value

      # strip_tags and upcase
      value = ActionView::Base.full_sanitizer.sanitize(value).upcase
      value == 'PENNSYLVANIA' ? 'PA' : nil
      value.presence_in(STATES)
    end

    def normalize_zipcode(row)
      [
        row_value(row, field: 'zip', required: false),
        row_value(row, field: 'Zipextension', required: false),
      ].compact.join('-')
    end

    def model_class
      Hmis::Hud::CustomClientAddress
    end
  end
end
