###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class DashboardExportFile < GrdaWarehouse::File
    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

  end
end
