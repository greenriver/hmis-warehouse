###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class BaseLoader
    attr_reader :reader, :clobber

    def self.perform(...)
      new(...).perform
    end

    def initialize(reader:, clobber: false)
      @reader = reader
      @clobber = clobber
    end

    protected

    def parse_date(str)
      Date.parse(str)
    end

    def cde_definition(owner_type:, key:)
      @cache ||= {}
      @cache[[owner_type, key]] ||= cde_definitions.find_or_create(owner_type: owner_type, key: key)
    end

    def cde_definitions
      @cde_definitions ||= CustomDataElementDefinitions.new(data_source_id: data_source.id, system_user_id: system_user_id)
    end

    def row_value(row, field:, required: true)
      value = row[field]&.strip&.presence
      raise "field '#{field}' is missing" if required && !value

      value
    end

    def system_user_id
      @system_user_id || Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
    end

    def data_source
      HmisExternalApis::AcHmis.data_source
    end

    def default_attrs
      {
        data_source_id: data_source.id,
        UserID: system_user_id,
      }
    end

    def today
      @today ||= Date.current
    end
  end
end
