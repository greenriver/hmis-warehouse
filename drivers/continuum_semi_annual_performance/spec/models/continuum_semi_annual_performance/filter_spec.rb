###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::Filter, type: :model do
  let(:user) { create(:acl_user) }
  let(:base) { { user_id: user.id, start: Date.new(2026, 1, 1), end: Date.new(2026, 6, 30), enforce_one_year_range: false } }

  it 'is valid with exactly one CoC code' do
    expect(described_class.new(**base, coc_codes: ['XX-500']).valid?).to be(true)
  end

  it 'rejects two CoC codes' do
    filter = described_class.new(**base, coc_codes: ['XX-500', 'XX-501'])

    expect(filter.valid?).to be(false)
    expect(filter.errors[:coc_codes]).to include('must include exactly one CoC')
  end

  it 'rejects no CoC code' do
    filter = described_class.new(**base, coc_codes: [])

    expect(filter.valid?).to be(false)
    expect(filter.errors[:coc_codes]).to be_present
  end
end
