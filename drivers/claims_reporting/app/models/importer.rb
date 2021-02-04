# Class to handle upsert style inserts from ZIPED CSVs (and potentially other flat file formats
# into ClaimsReporting::* data tables.
require 'net/sftp'
require 'zip'

module ClaimsReporting
  class Importer
    attr_reader :import
    attr_accessor :logger

    def self.default_credentials
      YAML.safe_load(ERB.new(File.read(Rails.root.join('config/health_sftp.yml'))).result)[Rails.env]['ONE']
    end

    def self.clear!
      raise 'Disabled' unless Rails.env.development? || Rails.env.test?

      HealthBase.logger.warn { "#{self}.clear! truncating/clearing all tables" }
      [MemberRoster, MemberEnrollmentRoster, MedicalClaim, RxClaim].each do |klass|
        klass.connection.truncate(klass.table_name)
      end
      nil
    end

    def initialize
      @logger = HealthBase.logger
    end

    # credentials is a Hash containing host, username, password
    # defaults to one from config/health_sftp.yml
    def pull_from_health_sftp(zip_path, replace_all: false, credentials: nil)
      credentials ||= self.class.default_credentials

      record_start(
        :pull_from_health_sftp,
        { replace_all: replace_all },
        "sftp://#{credentials['host']}/#{zip_path}",
      )

      sftp = Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        password: credentials['password'],
        auth_methods: ['publickey', 'password'],
      )
      record_progress(step: :connected)
      logger.debug 'pull_from_health_sftp: connected, downloading...'
      Tempfile.create(File.basename(zip_path)) do |tmpfile|
        logger.debug "pull_from_health_sftp: to #{tmpfile.path}"
        sftp.download!(zip_path, tmpfile.path)
        record_progress(step: :download)
        logger.debug "downloaded #{tmpfile.path}"
        import_from_zip(tmpfile, replace_all: replace_all)
      end
    rescue Interrupt
      import.update!(
        completed_at: Time.current,
        status_message: 'Aborted',
        successful: false,
      )
      raise
    rescue StandardError => e
      import.update!(
        completed_at: Time.current,
        status_message: e.message,
        successful: false,
      )
      raise
    end

    # zip_path_or_io is passed Zip::InputStream.open
    # returns a hash of counts found per CSV file
    def import_from_zip(zip_path_or_io, replace_all: false)
      full_path = if zip_path_or_io.respond_to?(:path)
        File.expand_path ip_path_or_io.path
      else
        File.expand_path zip_path_or_io
      end

      record_start(
        :import_from_zip,
        { replace_all: replace_all },
        "file://#{full_path}",
      )
      import.update!(
        # content: File.read(full_path),
        content_hash: Digest::SHA256.file(full_path),
      )
      results = {
        step: :processing_zip_file,
      }

      files = [
        ['member_roster.csv', MemberRoster],
        ['member_enrollment_roster.csv', MemberEnrollmentRoster],
        ['medical_claims.csv', MedicalClaim],
        ['rx_claims.csv', RxClaim],
      ]
      # TODO? If the database CPU is available this could be parallelized
      Zip::InputStream.open(zip_path_or_io) do |io|
        while (entry = io.get_next_entry)
          files.each do |name_pattern, klass|
            next unless entry.name.ends_with?(name_pattern)

            logger.info "found #{entry.name}, importing..."
            results[name_pattern] = { step: :import_csv_data }
            record_progress results
            entry.get_input_stream do |entry_io|
              result = klass.import_csv_data(entry_io, filename: entry.name, replace_all: replace_all)
              results[name_pattern] = result
            end
            record_progress results
          end
        end
      end
      import.update!(
        completed_at: Time.current,
        results: results,
        successful: true,
      )
      results
    rescue Interrupt
      import.update!(
        completed_at: Time.current,
        status_message: 'Aborted',
        successful: false,
      )
      raise
    rescue StandardError => e
      import.update!(
        completed_at: Time.current,
        status_message: e.message,
        successful: false,
      )
      raise
    end

    private def record_start(method_name, method_args, source_url)
      logger.info "#{self.class}#record_start: #{method_name} #{method_args} #{source_url}"
      @import ||= ClaimsReporting::Import.create!(
        source_url: source_url,
        started_at: Time.current,
        importer: self.class,
        method: method_name,
        args: method_args,
      )
      return @import
    end

    private def record_progress(results)
      raise 'Need record_start before we can record_progres ' unless import.present?

      import.update!(results:  results)
      results
    end
  end
end
