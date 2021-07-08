# Class to handle upsert style inserts from ZIPED CSVs (and potentially other flat file formats
# into ClaimsReporting::* data tables.
require 'net/sftp'
require 'zip'

module ClaimsReporting
  class Importer
    attr_reader :import
    attr_accessor :logger

    def self.default_credentials
      YAML.safe_load(ERB.new(File.read(Rails.root.join('config/health_sftp.yml'))).result)[Rails.env]['ONE'].with_indifferent_access
    end

    def self.default_path
      GrdaWarehouse::Config.get(:health_claims_data_path)
    end

    def self.polling_enabled?
      default_credentials[:host].present? && default_path.present?
    end

    def self.nightly!
      return unless polling_enabled?

      new.import_all_from_health_sftp
    end

    def self.clear!
      raise 'Disabled' unless Rails.env.development? || Rails.env.test?

      Rails.logger.warn { "#{self}.clear! truncating/clearing all tables" }
      [MemberRoster, MemberEnrollmentRoster, MedicalClaim, RxClaim].each do |klass|
        klass.connection.truncate(klass.table_name)
      end
      nil
    end

    def initialize
      @logger = Rails.logger
    end

    DEFAULT_NAMING_CONVENTION = /(?<prefix>.*)_?(?<m>[a-z]{3})_(?<y>\d{4})\.zip\Z/i.freeze

    private def using_sftp(credentials)
      credentials ||= self.class.default_credentials
      host = credentials.fetch('host').presence or raise "'host:' must be provided or set via ENV['HEALTH_SFTP_HOST']"
      Net::SFTP.start(
        host,
        credentials['username'],
        password: credentials['password'],
        auth_methods: ['publickey', 'password'],
        keepalive: true,
        keepalive_interval: 60,
      ) do |connection|
        yield connection
      end
    end

    # returns an Array of Hashs describing
    # files sorted in ascending date order using the month and year found
    # in the file name. See naming_convention
    def check_sftp(
      naming_convention: DEFAULT_NAMING_CONVENTION,
      root_path: nil,
      show_import_status: true,
      credentials: self.class.default_credentials
    )
      root_path ||= self.class.default_path
      results = []
      using_sftp(credentials) do |sftp|
        sftp.dir.glob(root_path, '*.zip').each do |remote_file|
          md = remote_file.name.match(naming_convention)
          next unless md

          results << {
            path: File.join(root_path, remote_file.name),
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
          r[:last_successful_import_id] = ClaimsReporting::Import.where(
            source_url: sftp_url(credentials['host'], zip_path),
            successful: true,
          ).order(updated_at: :desc).limit(1).pluck(:id).first
        end
      end

      results.sort_by do |r|
        r[:date]
      end
    end

    # check_sftp and find any files we haven't successfully imported
    # in the past. Currently matches on the sftp url of the file
    # to save on downloads but could also check #content_hash if
    # files being changed is a problem
    def import_all_from_health_sftp(
      root_path: nil,
      naming_convention: DEFAULT_NAMING_CONVENTION,
      credentials: self.class.default_credentials,
      redo_past_imports: false
    )
      # Allow only one in progress call per DB.
      # We will be reading from our db, then an external SFTP
      # and then sync over any content we cant find. Ugly
      # race conditions exist if these are interleaved
      HealthBase.with_advisory_lock('import_all_from_health_sftp') do
        logger.info { 'ClaimsReporting::Importer#import_all_from_health_sftp' }
        results = check_sftp(
          naming_convention: naming_convention,
          root_path: root_path,
          show_import_status: true,
          credentials: credentials,
        )
        results.select do |r|
          if redo_past_imports || r[:last_successful_import_id].blank?
            @import = nil # paranoia, reset this since we are looping
            import_from_health_sftp(r[:path], credentials: credentials)
          else
            logger.debug { "Skipping #{r}" }
            false
          end
        end
      end
    end

    private def sftp_url(host, path)
      "sftp://#{File.join host, path}"
    end

    # credentials is a Hash containing host, username, password
    # defaults to one from config/health_sftp.yml
    def import_from_health_sftp(zip_path, replace_all: false, credentials: self.class.default_credentials)
      record_start(
        :import_from_health_sftp,
        { replace_all: replace_all },
        sftp_url(credentials['host'], zip_path),
      )

      Tempfile.create(File.basename(zip_path)) do |tmpfile|
        using_sftp(credentials) do |sftp|
          record_progress(step: :connected)
          logger.info 'import_from_health_sftp: connected, downloading...'
          record_progress(step: :downloading)
          logger.info "... to #{tmpfile.path}"
          sftp.download!(zip_path, tmpfile.path)
          sftp.loop # cargo-cult... maybe helps Net::SFTP stay alive
          record_progress(step: :downloaded)
          logger.info "... downloaded #{tmpfile.path}; disconnecting"
        end
        logger.info '... disconnected'
        import_from_zip(tmpfile, replace_all: replace_all, new_import: false)
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
    def import_from_zip(zip_path_or_io,
      replace_all: false,
      new_import: true,
      file_filter: nil)
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
        # content: File.open(full_path, 'rb', &:read),
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

            if file_filter && !file_filter.match?(entry.name)
              logger.warn "Skipping #{entry.name} which is not in #{file_filter.inspect}"
              next
            end

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

      results[:post_import_hook] = { started_at: Time.current }
      record_progress results
      run_post_import_hook(file_filter)
      results[:post_import_hook][:completed_at] = Time.current
      record_progress results

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

    def pending
      check_sftp.reject do |r|
        r[:last_successful_import_id].present?
      end.map do |info|
        File.basename(info[:path])
      end
    end

    private def run_post_import_hook(file_filter)
      if file_filter.nil? || file_filter.match?('member_enrollment_roster.csv')
        ClaimsReporting::MemberEnrollmentRoster.maintain_engagement!
        ClaimsReporting::MemberEnrollmentRoster.maintain_first_claim_date!
      end
      ClaimsReporting::MedicalClaim.maintain_engaged_days! if file_filter.nil? || file_filter.match?('medical_claims.csv')
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
