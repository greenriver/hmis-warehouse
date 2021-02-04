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

    DEFAULT_NAMING_CONVENTION = /(?<prefix>.*)_?(?<m>[a-z]{3})_(?<y>\d{4})\.zip\Z/i.freeze

    private def using_sftp(credentials)
      credentials ||= self.class.default_credentials
      Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        password: credentials['password'],
        auth_methods: ['publickey', 'password'],
      ) do |connection|
        yield connection
      end
    end

    # returns an Array of Hashs describing
    # files sorted in ascending date order using the month and year found
    # in the file name. See naming_convention
    def check_sftp(
      naming_convention: DEFAULT_NAMING_CONVENTION,
      root_path: '',
      show_import_status: true,
      credentials: self.class.default_credentials
    )
      results = []
      using_sftp(credentials) do |sftp|
        sftp.dir.glob(root_path, '*.zip').each do |remote_file|
          md = remote_file.name.match(naming_convention)
          next unless md

          results << {
            path: root_path + '/' + remote_file.name,
            prefix: md[:prefix],
            month: md[:m],
            year: md[:y],
            date: begin
                    Date.parse("#{md[:y]}-#{md[:m]}-1")
                  rescue StandardError
                    nil
                  end,
          }
        end
      end

      # FIXME? N+1 DB query but N will be small for years
      if show_import_status
        results.each do |r|
          zip_path = r[:path]
          existing = ClaimsReporting::Import.order(:updated_at).find_by(
            source_url: sftp_url(credentials['host'], zip_path),
            successful: true,
          )
          r[:last_successful_import_id] = existing&.id
        end
      end

      results.sort_by do |r|
        r[:date]
      end
    end

    def import_all_from_health_sftp(
      naming_convention: DEFAULT_NAMING_CONVENTION,
      root_path: '',
      credentials: self.class.default_credentials
    )
      results = check_sftp(
        naming_convention: naming_convention,
        root_path: root_path,
        show_import_status: true,
        credentials: credentials,
      )
      results.map do |r|
        if r[:last_successful_import_id]
          r
        else
          @import = nil
          import_from_health_sftp(r[:path], credentials: credentials)
        end
      end
    end

    # credentials is a Hash containing host, username, password
    # defaults to one from config/health_sftp.yml
    def import_from_health_sftp(zip_path, replace_all: false, credentials: self.class.default_credentials)
      record_start(
        :import_from_health_sftp,
        { replace_all: replace_all },
        sftp_url(credentials['host'], zip_path),
      )

      using_sftp(credentials) do |sftp|
        record_progress(step: :connected)
        logger.debug 'import_from_health_sftp: connected, downloading...'
        Tempfile.create(File.basename(zip_path)) do |tmpfile|
          record_progress(step: :downloading)
          logger.debug "import_from_health_sftp: to #{tmpfile.path}"
          sftp.download!(zip_path, tmpfile.path)
          record_progress(step: :download)
          logger.debug "downloaded #{tmpfile.path}"
          import_from_zip(tmpfile, replace_all: replace_all, new_import: false)
        end
      end
    rescue Interrupt
      record_complete(successful: false, status_message: 'Aborted')
      raise
    rescue StandardError => e
      record_complete(successful: false, status_message: e.message)
      raise
    end

    # zip_path_or_io is passed Zip::InputStream.open
    # returns a hash of counts found per CSV file
    def import_from_zip(zip_path_or_io, replace_all: false, new_import: true)
      full_path = if zip_path_or_io.respond_to?(:path)
        File.expand_path zip_path_or_io.path
      else
        File.expand_path zip_path_or_io
      end

      if new_import
        record_start(
          :import_from_zip,
          { replace_all: replace_all },
          "file://#{full_path}",
        )
      end

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
      record_complete(successful: true, status_message: '')
      import.update!(
        completed_at: Time.current,
        results: results,
        successful: true,
      )
      results
    rescue Interrupt
      record_complete(successful: false, status_message: 'Aborted')
      raise
    rescue StandardError => e
      record_complete(successful: false, status_message: e.message)
      raise
    end

    private def record_start(method_name, method_args, source_url)
      logger.info "#{self.class}#record_start: #{method_name} #{method_args} #{source_url}"
      @import = ClaimsReporting::Import.create!(
        source_url: source_url,
        started_at: Time.current,
        importer: self.class,
        method: method_name,
        args: method_args,
      )
      return @import
    end

    private def record_progress(new_results)
      raise 'Need record_start before we can record_progres ' unless import.present?

      results = (import.results || {}).merge(new_results)
      import.update!(results: results)
      results
    end

    private def record_complete(successful:, status_message: nil)
      import.update!(
        completed_at: Time.current,
        successful: successful,
        status_message: status_message,
      )
    end
  end
end
