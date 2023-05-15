###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Household, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  let!(:e1) { create(:hmis_hud_enrollment, project: p1, client: c1, user: u1, data_source: ds1, household_id: '123', entry_date: Date.today) }

  it 'has the right associations' do
    hh = Hmis::Hud::Household.first
    expect(Hmis::Hud::Household.all).to contain_exactly(hh)
    expect(hh.project).to eq(p1)
    expect(hh.enrollments).to contain_exactly(e1)
    expect(hh.clients).to contain_exactly(c1)
    expect(hh.household_size).to eq(1)
  end

  describe 'scope tests' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Test', last_name: 'User' }
    let!(:e2) { create :hmis_hud_enrollment, project: p1, client: c2, user: u1, data_source: ds1, household_id: '456', entry_date: Date.yesterday }

    it 'should handle text search correctly' do
      expect(Hmis::Hud::Household.client_matches_search_term('user')).to contain_exactly(Hmis::Hud::Household.find_by(HouseholdID: e2.household_id))
    end

    it 'should handle open on correctly' do
      e3 = create(:hmis_hud_enrollment, project: p1, user: u1, data_source: ds1, household_id: '789', entry_date: Date.today - 1.week)
      create(:hmis_hud_exit, data_source: ds1, enrollment: e3, client: c2, exit_date: Date.yesterday)

      expect(Hmis::Hud::Household.open_on_date(Date.today)).to contain_exactly(e1.household, e2.household)
      expect(Hmis::Hud::Household.open_on_date(Date.yesterday)).to contain_exactly(e2.household, e3.household)
      expect(Hmis::Hud::Household.open_on_date(Date.today - 3.days)).to contain_exactly(e3.household)
    end

    it 'should handle enrollment limit correctly' do
      e2.save_in_progress

      expect(Hmis::Hud::Household.in_progress).to contain_exactly(e2.household)
      expect(Hmis::Hud::Household.not_in_progress).to contain_exactly(e1.household)
    end
  end

  it 'should do nothing on delete' do
    hh = Hmis::Hud::Household.first

    # Should be a no-op
    expect { hh.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)

    expect(e1.persisted?)
    expect(c1.persisted?)
    expect(p1.persisted?)
    expect(u1.persisted?)

    expect(Hmis::Hud::Household.all).to contain_exactly(Hmis::Hud::Household.find_by(HouseholdID: e1.household_id))
  end
end
