###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Abstract class
module HmisExternalApis::TcHmis::Importers::Loaders
  class BaseLoader
    include SafeInspectable
    attr_reader :reader, :clobber, :tracker, :table_names, :log_file

    def self.perform(...)
      new(...).perform
    end

    def initialize(reader:, tracker: nil, clobber:, log_file:)
      @reader = reader
      @clobber = clobber
      @tracker = tracker
      @log_file = log_file
      @table_names = []
    end

    protected

    def supports_upsert?
      false
    end

    def runnable?
      clobber ? true : supports_upsert?
    end

    DATE_FMT = '%Y-%m-%d'.freeze
    DATE_RGX = /\A\d{4}-\d{2}-\d{2}\z/

    # 'YYYY-MM-DDT00:00:00.0000000'
    DATE_TIME_FMT = '%Y-%m-%dT%H:%M:%S.%N'.freeze
    DATE_TIME_RGX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{7}\z/

    def parse_date(str)
      return unless str

      case str
      when DATE_RGX
        Date.strptime(str, DATE_FMT)
      when DATE_TIME_RGX
        DateTime.strptime(str, DATE_TIME_FMT)
      else
        raise ArgumentError, "Invalid date or date-time format: '#{str}'"
      end
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
      @data_source ||= HmisExternalApis::TcHmis.data_source
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
      when '.'
        # for element 12180 in the HAT, the dot appears to mean 'true'
        true
      when nil
        nil
      else
        raise "unknown y/n value #{str}"
      end
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
      warning = result.ids.size == records.size ? nil : "(WARNING, expected to insert #{records.size} records)"
      log_info "inserted #{result.ids.size} records into #{table_name} #{warning}"
    end

    def log_info(msg)
      msg = "#{loader_name}: #{msg}"
      append_to_log(msg)
      Rails.logger.info msg
    end

    def append_to_log(msg)
      return unless log_file

      File.open(log_file, 'a') { |f| f.puts(msg) }
    end

    def cde_helper
      @cde_helper ||= CustomDataElementHelper.new(data_source: data_source, system_user: system_user, today: today)
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

    def log_skipped_row(row, field:)
      value = row.field_value(field)
      log_info "#{row.context} could not resolve \"#{field}\":\"#{value}\""
    end

    def log_processed_result(name: nil, expected:, actual:)
      name ||= model_class.name
      rate = expected.zero? ? 0 : (actual.to_f / expected).round(3)
      log_info("processed #{name}: #{actual} of #{expected} records (#{((1.0 - rate) * 100).round(2)}% skipped)")
    end
  end
end
