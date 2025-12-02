###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

  end
end
