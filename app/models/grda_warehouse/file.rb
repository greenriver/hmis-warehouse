###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class File < GrdaWarehouseBase
    acts_as_paranoid
    belongs_to :user

    mount_uploader :file, FileUploader # Tells rails to use this uploader for this model.
    validates :file, antivirus: true
  end
end
