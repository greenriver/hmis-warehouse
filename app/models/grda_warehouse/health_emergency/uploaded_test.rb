###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::HealthEmergency
  class UploadedTest < GrdaWarehouseBase
    include ::HealthEmergency
    include ArelHelper
    acts_as_paranoid

    belongs_to :batch, class_name: 'GrdaWarehouse::HealthEmergency::TestBatch', inverse_of: :uploaded_tests
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :test, optional: true

    scope :test_addition_pending, -> do
      where.not(client_id: nil).
      where(test_id: nil)
    end
  end
end