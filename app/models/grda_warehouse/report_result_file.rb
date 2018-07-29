module GrdaWarehouse
  class ReportResultFile < GrdaWarehouse::File

    def save_zip_to(path)
      reconstitute_path = ::File.join(path, 'report_result.zip')
      FileUtils.mkdir_p(path) unless ::File.directory?(path)
      ::File.open(reconstitute_path, 'w+b') do |file|
        file.write(content)
      end
      reconstitute_path
    end
  end
end
