###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'with ce processing setup' do
  let!(:destination_data_source) { create :destination_data_source }
  let!(:client1) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client3) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  let!(:pool) { create(:hmis_ce_match_candidate_pool) }
  let!(:opportunity) { create(:hmis_ce_opportunity, candidate_pool: pool) }
  let(:now) { Time.current }

  before(:all) { cleanup_test_environment }

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end
end
