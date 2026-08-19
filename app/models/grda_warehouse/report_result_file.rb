###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class ReportResultFile < GrdaWarehouse::File
    has_one_attached :report_result_file, dependent: false

    def file_data
      return report_result_file.download if report_result_file.attached?

      content
    end

    def save_zip_to(path)
      reconstitute_path = ::File.join(path, 'report_result.zip')
      FileUtils.mkdir_p(path) unless ::File.directory?(path)
      ::File.open(reconstitute_path, 'w+b') do |file|
        file.write(file_data)
      end
      reconstitute_path
    end
  end
end
