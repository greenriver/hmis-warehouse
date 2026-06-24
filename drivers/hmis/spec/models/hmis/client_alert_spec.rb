###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::ClientAlert, type: :model do
  include_context 'hmis base setup'
  describe 'basic client alert tests' do
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }
    let!(:a1) { create :hmis_client_alert, created_by: hmis_user }

    it 'client alert is saved successfully and connected to the saving user' do
      expect(a1.created_by.class).to eq(Hmis::User)
    end
  end
end
