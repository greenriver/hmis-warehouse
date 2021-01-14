# Class to handle upsert style inserts from ZIPED CSVs (and potentially other flat file formats
# into ClaimsReporting::* data tables.
require 'net/sftp'
require 'zip'

module ClaimsReporting
  class Importer
    def self.default_credentials
      YAML.safe_load(ERB.new(File.read(Rails.root.join('config/health_sftp.yml'))).result)[Rails.env]['ONE']
    end

    def logger
      HealthBase.logger
    end

    # credentials is a Hash containing host, username, password
    # defaults to one from config/health_sftp.yml
    def pull_from_health_sftp(zip_path, replace_all: false, credentials: nil)
      credentials ||= self.class.default_credentials
      sftp = Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        password: credentials['password'],
        auth_methods: ['publickey', 'password'],
      )
      logger.debug 'pull_from_health_sftp: connected, downloading...'
      Tempfile.create(File.basename(zip_path)) do |tmpfile|
        logger.debug "pull_from_health_sftp: to #{tmpfile.path}"
        sftp.download!(zip_path, tmpfile.path)
        logger.debug "downloaded #{tmpfile.path}"
        import_from_zip(tmpfile, replace_all: replace_all, entry_path: entry_path)
      end
    end

    # zip_path_or_io is passed Zip::InputStream.open
    def import_from_zip(zip_path_or_io, replace_all: true)
      logger.info "import_from_zip(#{zip_path_or_io}, replace_all: #{replace_all})"
      Zip::InputStream.open(zip_path_or_io) do |io|
        while (entry = io.get_next_entry)
          case entry.name
          when /medical_claims.csv\z/
            logger.info "import_from_zip: found #{entry.name}, reading..."
            entry.get_input_stream do |entry_io|
              MedicalClaim.import_csv_data(entry_io, filename: entry.name, replace_all: replace_all)
            end
          when /member_roster.csv\z/
            logger.info "import_from_zip: found #{entry.name}, reading..."
            entry.get_input_stream do |entry_io|
              MemberRoster.import_csv_data(entry_io, filename: entry.name, replace_all: replace_all)
            end
          when /rx_claim.csv\z/
            logger.info "import_from_zip: found #{entry.name}, reading..."
            entry.get_input_stream do |entry_io|
              RxClaim.import_csv_data(entry_io, filename: entry.name, replace_all: replace_all)
            end
          end
        end
      end
    end
  end
end
