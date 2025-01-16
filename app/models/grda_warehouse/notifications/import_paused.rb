###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This notification should be called when an import is paused.
# Imports are paused when they reach a set threshold of errors or changes
module GrdaWarehouse::Notifications
  class ImportPaused < Base
    has_many :notification_configurations
  end
end
