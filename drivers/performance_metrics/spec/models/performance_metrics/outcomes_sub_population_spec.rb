###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# The RRH and PSH sections read Reporting::Housed through the outcomes reports, which
# don't know the registered sub-populations. The report's sub-population must still
# limit which housed stays are counted.
RSpec.describe PerformanceMetrics::OutcomesSubPopulation, type: :model do
  let(:veteran_yes) { HudHelper.util.no_yes_reasons_for_missing_data_options.key('Yes') }
  let(:veteran_no) { HudHelper.util.no_yes_reasons_for_missing_data_options.key('No') }
  let(:rrh_type) { HudHelper.util.project_type_number_from_code(:rrh).first }
  let(:psh_type) { HudHelper.util.project_type_number_from_code(:psh).first }

  def create_stay(client_id, project_type: rrh_type, **attributes)
    Reporting::Housed.create!(
      client_id: client_id,
      project_type: project_type,
      dob: 30.years.ago.to_date,
      individual_adult: false,
      children_only: false,
      veteran_status: veteran_no,
      **attributes,
    )
  end

  let!(:veteran_adult) { create_stay(1, veteran_status: veteran_yes, individual_adult: true) }
  let!(:unknown_veteran_adult) { create_stay(2, veteran_status: nil, individual_adult: true) }
  let!(:parent) { create_stay(3) }
  let!(:child_with_parent) { create_stay(4, dob: 5.years.ago.to_date) }
  let!(:child_alone) { create_stay(5, dob: 16.years.ago.to_date, children_only: true) }
  let!(:unknown_age) { create_stay(6, dob: nil) }

  def restricted_client_ids(sub_population)
    described_class.new(sub_population).
      restrict(Reporting::Housed.all).
      pluck(:client_id)
  end

  it 'keeps every stay for all clients' do
    expect(restricted_client_ids(:clients)).to contain_exactly(1, 2, 3, 4, 5, 6)
  end

  it 'keeps veterans' do
    expect(restricted_client_ids(:veterans)).to contain_exactly(1)
  end

  it 'keeps non-veterans, including a missing veteran status' do
    expect(restricted_client_ids(:non_veterans)).to contain_exactly(2, 3, 4, 5, 6)
  end

  it 'keeps adults in adult only households' do
    expect(restricted_client_ids(:adult_only_households)).to contain_exactly(1, 2)
  end

  it 'keeps children in child only households' do
    expect(restricted_client_ids(:child_only_households)).to contain_exactly(5)
  end

  it 'keeps adults and children in households with both, excluding an unknown age' do
    expect(restricted_client_ids(:adults_with_children)).to contain_exactly(3, 4)
  end

  [:adults_with_children_youth_hoh, :adults_with_children_twentyfive_plus_hoh].each do |sub_population|
    it "keeps no stays for #{sub_population}, which Reporting::Housed can't identify" do
      sub_population_filter = described_class.new(sub_population)

      expect(sub_population_filter).not_to be_supported
      expect(restricted_client_ids(sub_population)).to be_empty
    end
  end

  describe 'PerformanceMetrics::Report' do
    let(:user) { create(:acl_user) }
    let(:report) { PerformanceMetrics::Report.new(user_id: user.id) }

    before do
      create_stay(7, project_type: psh_type, veteran_status: veteran_yes)
      create_stay(8, project_type: psh_type)
      report.filter = Filters::FilterBase.new(user_id: user.id, sub_population: :veterans)
    end

    it 'limits the RRH stays to the chosen sub-population' do
      rrh_client_ids = report.send(:run_rrh).housed_source.pluck(:client_id)

      expect(rrh_client_ids).to contain_exactly(1)
    end

    it 'limits the PSH stays to the chosen sub-population' do
      psh_client_ids = report.send(:run_psh).housed_source.pluck(:client_id)

      expect(psh_client_ids).to contain_exactly(7)
    end

    it 'reports housed stays as available for a supported sub-population' do
      expect(report.housed_stays_available_for_sub_population?).to be true
    end
  end
end
