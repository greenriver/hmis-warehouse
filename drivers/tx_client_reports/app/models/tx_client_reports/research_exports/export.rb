###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports
  class ResearchExports::Export < GrdaWarehouse::File
    mount_uploader :file, FileUploader
    belongs_to :user
    belongs_to :file, class_name: 'GrdaWarehouse::File', optional: true
  end
end
