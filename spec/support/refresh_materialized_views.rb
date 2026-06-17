###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
  end
end
