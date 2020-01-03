###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user, required: true

    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.

  end
end
