###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
RSpec.describe Hmis::Hud::HmisService, type: :model do
  let(:ds1) { create :hmis_data_source }
  let!(:service_type) { create :hmis_custom_service_type_for_hud_service, data_source: ds1, name: 'some service' }
  let!(:service) { create :hmis_hud_service, data_source: ds1, record_type: service_type.hud_record_type, type_provided: service_type.hud_type_provided }

  it 'when an enrollment has an mismatched client, it is not included in services' do
    project = service.enrollment.project
    expect do
      # update_column skips validation
      service.enrollment.update_column(:personal_id, 'this_is_an_invalid_client_id')
    end.to change(project.hmis_services, :count).by(-1)
  end
end
