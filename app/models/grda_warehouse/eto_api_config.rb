###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class EtoApiConfig < GrdaWarehouseBase
    has_paper_trail
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY']

    belongs_to :data_source

  end
end