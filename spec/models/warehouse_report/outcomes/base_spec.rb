###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReport::Outcomes::Base::Support, type: :model do
  let(:user) { create(:user) }
  let(:support) { described_class.new(clients: [], rows: [], headers: ['first_name']) }

  describe '#display_value' do
    it 'does not raise when neither project_id nor client_id is present' do
      expect do
        support.display_value(header: 'first_name', value: 'Jamie', project_id: nil, client_id: nil, user: user)
      end.not_to raise_error
    end

    it 'does not redact the value under the fallback policy' do
      result = support.display_value(header: 'first_name', value: 'Jamie', project_id: nil, client_id: nil, user: user)
      expect(result).to eq('Jamie')
    end
  end
end
