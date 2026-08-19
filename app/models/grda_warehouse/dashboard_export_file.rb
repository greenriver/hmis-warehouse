###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    has_one_attached :dashboard_export_file, dependent: false

    def file_data
      return dashboard_export_file.download if dashboard_export_file.attached?

      content
    end

  end
end
