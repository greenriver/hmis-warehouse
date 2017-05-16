require 'net/sftp'
require 'csv'
require 'charlock_holmes'

module Health
  class Tasks::ImportEpic
    include TsqlImport
    attr_accessor :send_notifications, :notifier_config, :logger

    def initialize(logger: Rails.logger)
      @notifier_config = Rails.application.config_for(:exception_notifier) rescue nil
      @send_notifications = notifier_config && ( Rails.env.production? )
      @logger = logger
      @config = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      if @send_notifications
        @slack_url = @notifier_config['slack']['webhook_url']
        @channel   = @notifier_config['slack']['channel']
        @notifier  = Slack::Notifier.new(
          @slack_url, 
          channel: @channel, 
          username: 'HealthImporter'
        )        
      end
    end

    def run!
      fetch_files()
      import_files()
    end

    def import klass:, file:
      handle = read_csv_file(path: "#{@config['destination']}/#{file}")
      raise "Incorrect file format for #{file}" unless header_row_matches(file: handle, klass: klass)
    end

    def import_files
      Health.models_by_health_filename.each do |file, klass|
        import(klass: klass, file: file)
      end
    end

    def fetch_files
      sftp = Net::SFTP.start(
        @config['host'], 
        @config['username'], 
        password: @config['password']
      ) 
      sftp.download!(@config['path'], @config['destination'], recursive: true)
      msg = "Health data downloaded"
      @logger.info msg
      @notifier.ping msg if @send_notifications
    end

    def read_csv_file path:
      # Look at the file to see if we can determine the encoding
      @file_encoding = CharlockHolmes::EncodingDetector
        .detect(File.read(path))
        .try(:[], :encoding)
      file_lines = IO.readlines(path).size - 1
      @logger.info "Processing #{file_lines} lines in: #{path}"
      puts "r:bom|#{@file_encoding}"
      File.open(path, "r:bom|#{@file_encoding}")
    end

    def header_row_matches file:, klass:
      expected = klass.csv_map.keys.sort
      found = CSV.parse(file.first).first.map(&:to_sym).sort
      puts expected.inspect
      puts found.inspect
      found == expected
    end
  end
end