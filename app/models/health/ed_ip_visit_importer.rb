###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EdIpVisitImporter
    def sftp_credentials
      YAML.safe_load(ERB.new(File.read(Rails.root.join('config/health_sftp.yml'))).result)[Rails.env]['ONE'].with_indifferent_access
    end

    def polling_enabled?
      sftp_credentials[:host].present?
    end

    def daily!
      return unless polling_enabled?

      import_all_from_health_sftp
    end

    FILE_PATTERN = /(?<filename>.+\.csv)\Z/i.freeze

    private def import_all_from_health_sftp
      new_files.each do |filename|
        import_from_sftp(filename)
      end
    end

    private def new_files
      directory = "#{sftp_credentials[:path]}/CMT ED_IP Data"
      results = []
      most_recent_upload = Health::EdIpVisitFile.maximum(:created_at)
      using_sftp do |sftp|
        sftp.dir.glob(directory, '*.csv').each do |remote|
          match = remote.name.match(FILE_PATTERN)
          next unless match
          next if Time.at(remote.attributes.createtime) < most_recent_upload

          results << File.join(directory, match[:filename])
        end
      end
      results
    end

    private def import_from_sftp(file_path)
      Tempfile.create(File.basename(file_path)) do |tmpfile|
        using_sftp do |sftp|
          sftp.download!(file_path, tmpfile.path)
          file = Health::EdIpVisitFileV2.create(
            content: tmpfile.read,
            user: User.setup_system_user,
            file: File.basename(file_path),
          )
          Health::EdIpImportJob.perform_later(file.id)
        end
      end
    end

    private def using_sftp
      credentials = sftp_credentials
      Net::SFTP.start(
        credentials['host'],
        credentials['username'],
        password: credentials['password'],
        auth_methods: ['publickey', 'password'],
        keepalive: true,
        keepalive_interval: 60,
      ) do |connection|
        yield connection
      end
    end
  end
end
