require 'zip'
module Importers::HMISSixOneOne
  class UploadedZip < Base
    def initialize(
      file_path: 'var/hmis_import',
      data_source_id:,
      logger: Rails.logger,
      debug: true,
      upload_id:,
      deidentified: false,
      project_whitelist: false
    )
      super(
        file_path: file_path,
        data_source_id: data_source_id,
        logger: logger,
        debug: debug,
        deidentified: deidentified,
        project_whitelist: project_whitelist
      )
      @project_whitelist = project_whitelist
      @file_path = "#{file_path}/#{Time.now.to_i}"
      @local_path = "#{@file_path}/#{@data_source.id}"
      @data_source_id = data_source_id
      @upload = GrdaWarehouse::Upload.find(upload_id.to_i)
      @import.upload_id = @upload.id
      @import.save
    end

    def pre_process!
      file_path = reconstitute_upload()
      expand(file_path: file_path)
      if @upload.project_whitelist
        calculate_whitelisted_personal_ids(@local_path)
        remove_unwhitelisted_client_data(@local_path)
        replace_original_upload_file(file_path)
        remove_import_files
      end
    end

    def import!
      return unless @upload.present?
      file_path = reconstitute_upload()
      expand(file_path: file_path)
      super()
      mark_upload_complete()
    end

    def calculate_whitelisted_personal_ids file_path
      @whitelisted_project_ids = GrdaWarehouse::WhitelistedProjectsForClients.where(data_source_id: @data_source.id).pluck(:ProjectID).to_set

      # 1. See if we have you in the database already (which would mean you were in one of those projects previously)
      @whitelisted_personal_ids = GrdaWarehouse::Hud::Client.where(data_source_id: @data_source.id).pluck(:PersonalID).to_set

      # 2. See if you have an enrollment in one of the whitelisted projects in the incoming file.
      file = File.join(file_path, importable_files.key(enrollment_source))

      CSV.foreach(file, headers: true) do |row|
        if @whitelisted_project_ids.include?(row['ProjectID'])
          @whitelisted_personal_ids.add(row['PersonalID'])
        end
      end
    end

    def remove_unwhitelisted_client_data file_path
      [
        enrollment_coc_source,
        enrollment_source,
        exit_source,
        disability_source,
        employment_education_source,
        health_and_dv_source,
        income_benefits_source,
        service_source,
        client_source,
      ].each do |klass|
        file = File.join(file_path, importable_files.key(klass))
        clean_file = File.join(file_path, "clean_#{importable_files.key(klass)}")
        CSV.open(clean_file, 'wb') do |csv|
          line = File.open(file).readline
          # Make sure header is in our format
          csv << CSV.parse(line)[0].map {|k| k.downcase.to_sym}
          CSV.foreach(file, headers: true) do |row|
            # only keep row if PersonalID is in whitelisted clients
            csv << row if @whitelisted_personal_ids.include?(row['PersonalID'])
          end
        end

        FileUtils.mv(clean_file, file)
      end
    end

    def replace_original_upload_file zip_file_path
      #rezip files
      files = Dir.glob(File.join(@local_path, '*')).map{|f| File.basename(f)}
      Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
       files.each do |filename|
        zipfile.add(
          filename,
          File.join(@local_path, filename)
        )
        end
      end

      #update upload with new zip
      @upload.file = File.new(zip_file_path)
      @upload.content_type = @upload.file.content_type
      @upload.content = @upload.file.read
      @upload.save
    end

    def remove_import_files
      Rails.logger.info "Removing #{@file_path}"
      FileUtils.rm_rf(@file_path) if File.exists?(@file_path)
    end

    def reconstitute_upload
      reconstitute_path = "#{@local_path}/#{@upload.file.file.filename}"
      Rails.logger.info "Re-constituting upload file to: #{reconstitute_path}"
      FileUtils.mkdir_p(@local_path) unless File.directory?(@local_path)
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(@upload.content)
      end
      reconstitute_path
    end

  end
end
