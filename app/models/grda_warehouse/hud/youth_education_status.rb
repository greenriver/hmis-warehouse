###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class YouthEducationStatus < Base
    include ::HMIS::Structure::YouthEducationStatus
    include RailsDrivers::Extensions

    # TODO This a placeholder class to be completed as part of the 2022 spec implmementation
  end
end
