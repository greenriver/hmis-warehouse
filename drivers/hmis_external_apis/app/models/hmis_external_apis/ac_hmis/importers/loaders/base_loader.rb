###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class BaseLoader
    attr_reader :reader, :clobber, :tracker, :table_names

    def self.perform(...)
      new(...).perform
    end

    def initialize(reader:, tracker: nil, clobber:)
      @reader = reader
      @clobber = clobber
      @tracker = tracker
      @table_names = []
    end

    protected

    def supports_upsert?
      false
    end

    def runnable?
      clobber ? true : supports_upsert?
    end

    # 'YYYY-MM-DD HH24:MM:SS'
    DATE_TIME_FMT = '%Y-%m-%d %H:%M:%S'.freeze
    def valid_date?(str)
      str =~ /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/
    end

    def parse_date(str)
      return unless str
      raise ArgumentError, "Invalid date-time format. Expected 'YYYY-MM-DD HH24:MM:SS' but got '#{str}'" unless valid_date?(str)

      DateTime.strptime(str, DATE_TIME_FMT)
    end

    def cde_definition(owner_type:, key:)
      @cache ||= {}
      @cache[[owner_type, key]] ||= cde_definitions.find_or_create(owner_type: owner_type, key: key)
    end

    def cde_definitions
      @cde_definitions ||= CustomDataElementDefinitions.new(data_source_id: data_source.id, system_user_id: system_user_id)
    end

    # note: it would be cleaner for this method to live in CsvFileRowWrapper
    def row_value(row, field:, required: true)
      value = row[field]&.strip&.presence
      raise "field '#{field}' is missing from row: #{row.to_h.inspect}" if required && !value

      value
    end

    def system_user_id
      system_hud_user.user_id
    end

    def system_user_pk
      system_user.id
    end

    def system_hud_user
      @system_hud_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def system_user
      @system_user ||= Hmis::User.system_user
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
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
      case str
      when /^(y|yes)$/i
        true
      when /^(n|no)$/i
        false
      when nil
        nil
      else
        raise "unknown y/n value #{str}"
      end
    end

    def assign_next_unit(...)
      tracker.assign_next_unit(...)
    end

    def ar_import(import_class, records, **args)
      records = records.compact
      table_name = import_class.table_name
      raise "#{loader_name} unexpected empty records for #{table_name}" if records.empty?

      defaults = { batch_size: 1_000, validate: false }
      result = import_class.import(records, defaults.merge(args))
      if result.failed_instances.present?
        msg = "#{loader_name} failed: #{result.failed_instances} into #{table_name}"
        raise msg
      end
      table_names.push(table_name)

      # report ids.size, since num_inserts is only last batch
      log_info "inserted #{result.ids.size} records into #{table_name}"
    end

    def log_info(msg)
      Rails.logger.info "#{loader_name}: #{msg}"
    end

    def loader_name
      self.class.name
    end

    # some record sets can't be bulk inserted. Disabling paper trial reduces runtime when
    # we have to fallback to individual inserts
    def without_paper_trail
      enabled = PaperTrail.enabled?
      begin
        PaperTrail.enabled = false
        yield
      ensure
        PaperTrail.enabled = enabled
      end
    end

    def to_s
      inspect
    end

    # reduce clutter in debugging output, avoids logging memoized values
    def inspect
      self.class.name.to_s
    end

    def log_skipped_row(row, field:)
      value = row_value(row, field: field)
      log_info "#{row.context} could not resolve \"#{field}\":\"#{value}\""
    end
  end
end
