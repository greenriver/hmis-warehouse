###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Fy2020
  class AprLivingSituation < GrdaWarehouseBase
    belongs_to :apr_client, class_name: 'HudApr::Fy2020::AprClient'
  end
end