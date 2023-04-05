###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module YouthExport
  extend ActiveSupport::Concern
  included do
    def for_export
      data = self.class.user_data.values.map do |method|
        user.public_send(method)
      end

      data += self.class.report_columns_for_export.map do |method|
        clean_value(public_send(method))
      end

      data += self.class.intake_data.values.map do |method|
        clean_value(youth_intakes.select { |m| m.created_at <= created_at }.
          max_by(&:updated_at)&.public_send(method))
      end
      data
    end

    def clean_value(value)
      if [true, false].include?(value)
        value = if value then 'Yes' else 'No' end
      end
      value = '' if value == '[]'
      value = value.map(&:presence).compact.join(', ') if value.is_a?(Array)

      value
    end

    def self.report_columns
      column_names - ['user_id', 'deleted_at']
    end

    def self.intake_data
      {
        first_name: :first_name,
        last_name: :last_name,
        client_race: :race_array,
        client_ethnicity: :ethnicity_description,
        client_gender: :gender,
        client_lgbtq: :client_lgbtq,
      }
    end

    def self.intake_headers
      intake_data.keys.map(&:to_s)
    end

    def self.user_data
      {
        entered_by_user: :name,
        user_email: :email,
        user_agency: :agency_name,
      }
    end

    def self.user_headers
      user_data.keys.map(&:to_s)
    end

    def self.export_headers
      all_headers = user_headers + report_columns + intake_headers
      return all_headers if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      all_headers.excluding('first_name', 'last_name', 'ssn', 'client_dob')
    end

    def self.report_columns_for_export
      return report_columns if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      report_columns.excluding('first_name', 'last_name', 'ssn', 'client_dob')
    end
  end
end
