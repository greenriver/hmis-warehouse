module GrdaWarehouse
  class HmisExport < GrdaWarehouseBase
    self.table_name = :exports
    attr_accessor :fake_data

    mount_uploader :file, HmisExportUploader

    belongs_to :user, class_name: User.name

    scope :ordered, -> do
      order(created_at: :desc)
    end

    scope :for_list, -> do
      select(column_names - ['content', 'file'])
    end

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