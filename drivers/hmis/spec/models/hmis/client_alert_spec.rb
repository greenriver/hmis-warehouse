###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ClientAlert, type: :model do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  describe 'basic client alert tests' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }
    let!(:a1) { create :hmis_client_alert, created_by: hmis_user }

    it 'client alert is saved successfully and connected to the saving user' do
      expect(a1.created_by.class).to eq(Hmis::User)
    end
  end
end
