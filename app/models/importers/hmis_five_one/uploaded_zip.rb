require 'zip'
module Importers::HMISFiveOne
  class UploadedZip < Base
    # conf = Importers::HMISFiveOne::Sftp.available_connections['SITE_NAME']
    #  Importers::HMISFiveOne::Sftp.new(data_source: 14, host: conf['host'], username: conf['username'], password: conf['password'], path: conf['path'])
    def initialize(
      file_path: 'var/hmis_import',
      data_source:,
      logger: Rails.logger, 
      debug: true,
      upload_id:
    )
      super(
        file_path: file_path, 
        data_source: data_source, 
        logger: logger, 
        debug: debug
      )
      @file_path = "#{file_path}/#{Time.now.to_i}/"
      @local_path = "#{@file_path}/#{@data_source.id}"
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
    end

    def import!
      return unless @upload.present?
      reconstitute_upload()
      expand(file_path: file_path)
      super()
      @import.update(percent_complete: 100) 
    end

    def expand file_path:
      Zip::File.open(file_path) do |zipped_file|
        zipped_file.each do |entry|
          entry.extract([@local_path, entry.name].join('/'))
        end
      end
      FileUtils.rm(file_path)
    end

    def reconstitute_upload
      reconstitute_path = @upload.file.current_path
      Rails.logger.info "Re-constituting upload file to: #{reconstitute_path}"
      FileUtils.mkdir_p(File.dirname(reconstitute_path)) unless File.directory?(File.dirname(reconstitute_path))
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(@upload.content)
      end
      return unless File.exist?(@upload.file.current_path)
      begin
        unzipped_files = []
        @logger.info "Unzipping #{@upload.file.current_path}"
        Zip::File.open(@upload.file.current_path) do |zip_file|
          zip_file.each do |entry|
            file_name = entry.name.split('/').last
            next unless file_name.include?('.csv')
            @logger.info "Extracting #{file_name}"
            unzip_path = "#{extract_path}/#{file_name}"
            @logger.info "To: #{unzip_path}"
            unzip_parent = File.dirname(unzip_path)
            FileUtils.mkdir_p(unzip_parent) unless File.directory?(unzip_parent)
            entry.extract(unzip_path)
            unzipped_files << [GrdaWarehouse::Hud.hud_filename_to_model(file_name).name, unzip_path] if file_name.include?('.csv')
          end
        end
      rescue StandardError => ex
        Rails.logger.error ex.message
        raise "Unable to extract file: #{@upload.file.current_path}"
      end
      # If the file was extracted successfully, delete the source file,
      # we have a copy in the database
      File.delete(@upload.file.current_path) if File.exist?(@upload.file.current_path)
      # archive_path = File.dirname(@upload.file.current_path.sub(Rails.root.to_s + '/tmp/', "var/upload_archive/#{Date.today.strftime("%Y-%m-%d")}/"))
      # FileUtils.mkdir_p(archive_path) unless File.directory?(archive_path)
      # FileUtils.mv(@upload.file.current_path, archive_path) if File.exist?(@upload.file.current_path)
      @upload.update({percent_complete: 0.01, unzipped_files: unzipped_files, import_errors: []})
      @upload.save!
    end
      
    def copy_from_sftp
      return unless @sftp.present?
      return unless file = fetch_most_recent()
      log("Found #{file}")
      # atool has trouble overwriting, so blow away whatever we had before
      FileUtils.rmtree(@local_path) if File.exists? @local_path
      FileUtils.mkdir_p(@local_path) 
      @sftp.download!("#{@sftp_path}/#{file}", "#{@local_path}/#{file}")
      file_path = force_standard_zip(file)
    end

  end
end