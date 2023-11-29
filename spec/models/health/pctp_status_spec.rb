require 'rails_helper'

RSpec.describe 'PCTP status', type: :model do
  let!(:careplan) { create :pctp_careplan }

  it 'checks that a completed careplan in the last year is active' do
    careplan.instrument.careplan_sent_on = Date.current - 6.months

    expect(careplan.active?).to be true
    expect(careplan.expiring?).to be false
    expect(careplan.expired?).to be false
  end

  it 'checks that a completed careplan that is ending soon is expiring' do
    careplan.instrument.careplan_sent_on = Date.current - 11.months - 1.day

    expect(careplan.active?).to be true
    expect(careplan.expiring?).to be true
    expect(careplan.expired?).to be false
  end

  it 'checks that a completed careplan that has ended has expired' do
    careplan.instrument.careplan_sent_on = Date.current - 13.months

    expect(careplan.active?).to be false
    expect(careplan.expiring?).to be false
    expect(careplan.expired?).to be true
  end
end
