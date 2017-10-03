module GrdaWarehouse
  class Export < GrdaWarehouseBase
    attr_accessor :fake_data

    mount_uploader :file, HmisExportUploader

    # TODO: There is currently no UI for exporting HMIS files, eventually it will
    # need a controller, views and a delayed job

    def save_zip_to(path)
      reconstitute_path = File.join(path, file.file.filename)
      FileUtils.mkdir_p(path) unless File.directory?(path)
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(content)
      end
      reconstitute_path
    end
  end
end