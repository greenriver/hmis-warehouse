###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HealthEmergency::Vaccination, type: :model do
  let(:client) { create(:grda_warehouse_hud_client) }
  let(:user) { create(:acl_user) }

  describe '#add_text_message_subscription' do
    it 'does not raise when follow_up_cell_phone is nil' do
      expect do
        described_class.create!(
          client: client,
          user: user,
          vaccinated_on: Date.current,
          vaccination_type: 'Janssen',
        )
      end.not_to raise_error
    end
  end
end
