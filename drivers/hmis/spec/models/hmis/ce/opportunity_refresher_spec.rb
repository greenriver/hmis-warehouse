# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Ce::OpportunityRefresher do
  include_context 'hmis base setup'

  let(:refresher) { described_class.new }

  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1) }
  let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p1) }

  let!(:ug1) { create(:hmis_unit_group, project: p1, workflow_template: workflow_template) }
  let!(:ug2) { create(:hmis_unit_group, project: p1, workflow_template: workflow_template) }

  let!(:eligibility1) { create(:hmis_ce_eligibility_requirement, owner: ug1, expression: 'current_age >= 18') }
  let!(:eligibility2) { create(:hmis_ce_eligibility_requirement, owner: ug2, expression: 'current_age >= 25') }
  let!(:priority_rule) { create(:hmis_ce_priority_scheme, owner: p1, expression: 'days_homeless') }

  before do
    # Trigger candidate pool creation
    Hmis::Ce::Match::CandidatePoolBuilder.call
    [ug1, ug2].each(&:reload)
  end

  let!(:unit1) { create(:hmis_unit, project: p1, unit_group: ug1) }
  let!(:unit2) { create(:hmis_unit, project: p1, unit_group: ug2) }
  let!(:unit3) { create(:hmis_unit, project: p1, unit_group: ug1) }

  # first 2 opportunities are stale and associated with the wrong candidate pool
  let!(:opportunity1) { create(:hmis_ce_opportunity, unit: unit1, project: p1, data_source: ds1, status: :open, stale: true, candidate_pool: ug2.candidate_pool) }
  let!(:opportunity2) { create(:hmis_ce_opportunity, unit: unit2, project: p1, data_source: ds1, status: :open, stale: true, candidate_pool: ug1.candidate_pool) }
  let!(:opportunity3) { create(:hmis_ce_opportunity, unit: unit3, project: p1, data_source: ds1, status: :open, stale: false, candidate_pool: ug1.candidate_pool) }

  describe '#refresh_stale_opportunities' do
    it 'closes stale opportunities and creates fresh ones' do
      result = refresher.refresh_stale_opportunities

      expect(result[:closed_count]).to eq(2)
      expect(result[:closed_opportunity_unit_ids]).to contain_exactly(unit1.id, unit2.id)
      expect(result[:created_count]).to eq(2)
      expect(result[:skipped_opportunity_ids]).to be_empty

      expect(opportunity1.reload.status).to eq('closed')
      expect(opportunity2.reload.status).to eq('closed')
      expect(opportunity3.reload.status).to eq('open')

      # Verify new opportunities were created and are associated with the correct candidate pool and rules
      new_opp1 = unit1.reload.latest_opportunity
      expect(new_opp1.status).to eq('open')
      expect(new_opp1.candidate_pool).to eq(ug1.candidate_pool)
      expect(new_opp1.assignment_rules.length).to eq(2)
      expect(new_opp1.assignment_rules.map { |r| r['id'] }).to contain_exactly(eligibility1.id, priority_rule.id)

      new_opp2 = unit2.reload.latest_opportunity
      expect(new_opp2.status).to eq('open')
      expect(new_opp2.candidate_pool).to eq(ug2.candidate_pool)
      expect(new_opp2.assignment_rules.length).to eq(2)
      expect(new_opp2.assignment_rules.map { |r| r['id'] }).to contain_exactly(eligibility2.id, priority_rule.id)
    end

    it 'only processes opportunities in candidate pool indicated' do
      result = refresher.refresh_stale_opportunities(candidate_pool_ids: [opportunity1.candidate_pool.id])

      expect(result[:closed_count]).to eq(1)
      expect(result[:closed_opportunity_unit_ids]).to contain_exactly(unit1.id)
      expect(opportunity1.reload.status).to eq('closed')
      expect(opportunity2.reload.status).to eq('open')
    end

    context 'when a stale opportunity has an active referral' do
      let!(:opportunity1) { create(:hmis_ce_opportunity, unit: unit1, project: p1, data_source: ds1, status: :locked, stale: true) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity1, data_source: ds1, status: :in_progress) }

      it 'does not close the stale opportunity with active referrals' do
        result = refresher.refresh_stale_opportunities

        expect(result[:closed_count]).to eq(1)
        expect(result[:closed_opportunity_unit_ids]).to contain_exactly(unit2.id)
        expect(result[:created_count]).to eq(1)
        expect(result[:skipped_opportunity_ids]).to contain_exactly(opportunity1.id)

        expect(opportunity1.reload.status).to eq('locked')
        expect(opportunity2.reload.status).to eq('closed')
      end
    end
  end
end
