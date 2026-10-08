###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::RunChronicJob, type: :job do
  it 'records the user who ran the report' do
    user = create(:acl_user)

    described_class.perform_now({ filter: { on: Date.current.to_s, min_age: 0, min_days_homeless: 0, last_service_after: 30 }, current_user_id: user.id })

    expect(GrdaWarehouse::WarehouseReports::ChronicReport.last.user_id).to eq(user.id)
  end
end
