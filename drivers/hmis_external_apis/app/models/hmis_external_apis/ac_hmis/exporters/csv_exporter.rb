###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters::CsvExporter
  extend ActiveSupport::Concern

  included do
    attr_accessor :output

    def initialize(output = StringIO.new)
      require 'csv'
      self.output = output
    end

    # Input: `Hmis::User` record (representing an application user in the `users` table)
    # Output: `id` of `Hmis::Hud::User` record from the `User` table, which matches exported User.csv file
    def to_hud_user_pk(app_user)
      @application_user_to_hud_user ||= {}

      raise 'expected app user' unless app_user.is_a?(Hmis::User) || app_user.is_a?(User)

      return @application_user_to_hud_user[app_user.id] if @application_user_to_hud_user.key?(app_user.id)

      # Find or Hmis Hud User record if one exists. Don't use User.from_user because we don't want to create a new user, just find existing one
      hud_user_id = Hmis::Hud::User.where(
        user_email: app_user.email.downcase,
        data_source_id: data_source.id,
      ).order(:id).first&.id

      @application_user_to_hud_user[app_user.id] = hud_user_id
      hud_user_id
    end

    private

    def write_row(row)
      output << CSV.generate_line(row, **csv_config)
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def csv_config
      {
        write_converters: ->(value, _) {
          if value.instance_of?(Date)
            value.strftime('%Y-%m-%d')
          elsif value.respond_to?(:strftime)
            value.strftime('%Y-%m-%d %H:%M:%S')
          elsif value.is_a?(String)
            value.gsub(/\r?\n/, ' ') # replace newlines with spaces (matches \n or \r\n)
          else
            value
          end
        },
      }
    end
  end
end
