###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
