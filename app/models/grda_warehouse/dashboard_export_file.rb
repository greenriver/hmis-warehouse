###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

  end
end
