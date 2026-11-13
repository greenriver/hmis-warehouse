###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.shared_context 'hmis simulation builder setup' do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.current }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client, project: project, EntryDate: date - 30) }
end
