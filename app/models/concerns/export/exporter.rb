###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Export::Exporter
  extend ActiveSupport::Concern
  include NotifierConfig

  included do
    def setup_export
      options = {
        user_id: @user&.id,
        start_date: @range.start,
        end_date: @range.end,
        period_type: @period_type,
        directive: @directive,
        hash_status: @hash_status,
        faked_pii: @faked_pii,
        confidential: @confidential,
        project_ids: @projects,
        include_deleted: @include_deleted,
        version: @version,
      }
      options[:export_id] = Digest::MD5.hexdigest(options.to_s)[0..31]

      @export = GrdaWarehouse::HmisExport.create(options)
      @export.fake_data = GrdaWarehouse::FakeData.where(environment: @faked_environment).first_or_create
    end

    def create_export_directory
      # make sure the path is clean
      FileUtils.rmtree(@file_path) if File.exist? @file_path
      FileUtils.mkdir_p(@file_path)
    end

    def save_fake_data
      return unless @faked_pii

      @export.fake_data.save
    end

    def zip_path
      @zip_path ||= File.join(@file_path, "#{@export.export_id}.zip")
    end

    def csv_file_path(klass)
      File.join(@file_path, klass.hud_csv_file_name(version: version))
    end

    def upload_zip
      @export.file = Pathname.new(zip_path).open
      @export.content_type = @export.file.content_type
      @export.content = @export.file.read
      @export.save
    end

    def zip_archive
      files = Dir.glob(File.join(@file_path, '*')).map { |f| File.basename(f) }
      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(
            # File.join(@export.export_id, filename),
            filename, # add without path
            File.join(@file_path, filename),
          )
        end
      end
    end

    def remove_export_files
      FileUtils.rmtree(@file_path) if File.exist? @file_path
    end

    def log(message)
      @notifier&.ping message
      logger.info message if @debug
    end

    def set_time_format
      # We need this for exporting to the appropriate format
      @default_date_format = Date::DATE_FORMATS[:default]
      @default_time_format = Time::DATE_FORMATS[:default]
      Date::DATE_FORMATS[:default] = '%Y-%m-%d'
      Time::DATE_FORMATS[:default] = '%Y-%m-%d %H:%M:%S'
    end

    def reset_time_format
      Date::DATE_FORMATS[:default] = @default_date_format
      Time::DATE_FORMATS[:default] = @default_time_format
    end
  end
end
