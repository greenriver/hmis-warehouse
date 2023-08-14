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

    def initialize(reader:, clobber: true)
      @reader = reader
      @clobber = clobber
      raise "upsert not supported" if !clobber && !supports_upsert?
    end

    protected

    def supports_upsert?
      false
    end

    # 'YYYY-MM-DD HH24:MM:SS'
    DATE_TIME_FMT = '%Y-%m-%d %H:%M:%S'
    def parse_date(str)
      raise ArgumentError, "Invalid date-time format. Expected 'YYYY-MM-DD HH24:MM:SS'" unless str =~ /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/

      DateTime.strptime(str, DATE_TIME_FMT)
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

    def yn_boolean(str)
      case str.downcase
      when /^(y|yes)$/
        true
      when /^(n|No)$/
        false
      end
    end

    def project_unit_tracker
      @project_unit_tracker = ProjectUnitTracker.new(data_source)
    end
  end
end
