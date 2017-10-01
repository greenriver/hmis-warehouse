require 'net/sftp'
require 'zip'
module Importers::HMISSixOneOne
  class Sftp < Base
    def initialize(
      file_path: 'var/hmis_import',
      data_source_id:,
      logger: Rails.logger, 
      debug: true,
      host:,
      username:,
      password:,
      path:
    )
      super(
        file_path: file_path, 
        data_source_id: data_source_id, 
        logger: logger, 
        debug: debug
      )
      @sftp = connect(host: host, username: username, password: password)
      @sftp_path = path
      @file_path = "#{file_path}/#{Time.now.to_i}"
      @local_path = "#{@file_path}/#{@data_source.id}"
    end

    def self.available_connections
      YAML::load(ERB.new(File.read(Rails.root.join("config","hmis_sftp.yml"))).result)[Rails.env]
    end

    def import!
      file_path = copy_from_sftp()
      # For local testing
      # file_path = copy_from_local()
      if file_path.present?
        upload(file_path: file_path)
      end
      expand(file_path: file_path)
      super()
      mark_upload_complete() 
    end

    def remove_import_files
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.exists?(@file_path)
    end

    def connect host:, username:, password:
      Rails.logger.info "Connecting to #{host}"
      Net::SFTP.start(
        host, 
        username,
        password: password,
        # verbose: :debug,
        auth_methods: ['publickey','password']
      )
    end
      
    def copy_from_sftp
      return unless @sftp.present?
      return unless file = fetch_most_recent()
      log("Found #{file}")
      FileUtils.rmtree(@local_path) if File.exists? @local_path
      FileUtils.mkdir_p(@local_path) 
      @sftp.download!("#{@sftp_path}/#{file}", "#{@local_path}/#{file}")
      file_path = force_standard_zip(file)
    end

    def force_standard_zip file
      file_path = "#{Rails.root.to_s}/#{@local_path}/#{file}"
      if File.extname(file_path) == '.7z'
        dest_file = file_path.gsub('.7z', '.zip')
        # Use atool convert the any 7zip files to zip for future processing
        system_call = "atool --repack -q #{file_path} #{dest_file}"
        Rails.logger.info "Asking the system to: #{system_call}"
        success = system(system_call)
        return nil unless success
        FileUtils.rm(file_path)
        file_path = dest_file
      end
      return file_path
    end

    def fetch_most_recent
      files = []
      @sftp.dir.foreach(@sftp_path) do |entry|
        files << entry.name
      end
      return nil if files.empty?
      # Fetch the most recent file
      file = files.max
      if file.present?
        return file
      end
      return nil
    end

    def upload file_path:
      @upload = GrdaWarehouse::Upload.new(
        percent_complete: 0.0, 
        data_source_id: @data_source.id, 
        user_id: 1,
      )
      @upload.file = Pathname.new(file_path).open
      @upload.content_type = @upload.file.content_type
      @upload.content = @upload.file.read
      @upload.save
    end
  end
end