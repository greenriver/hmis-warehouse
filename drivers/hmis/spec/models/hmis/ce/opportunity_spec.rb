# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Opportunity do
  let!(:organization) { create :hmis_hud_organization }
  let!(:project) { create :hmis_hud_project, organization: organization }
  let(:opportunity_attributes) { { project: project, data_source: project.data_source } }

  describe 'validations' do
    describe 'candidate pool stability' do
      let!(:pool1) { create(:hmis_ce_match_candidate_pool) }
      let!(:pool2) { create(:hmis_ce_match_candidate_pool) }

      context 'when opportunity already has a candidate pool' do
        let(:opportunity) { create(:hmis_ce_opportunity, **opportunity_attributes, candidate_pool: pool1) }

        it 'prevents changing to a different pool' do
          opportunity.candidate_pool = pool2

          expect(opportunity).not_to be_valid
          expect(opportunity.errors[:candidate_pool_id]).to include('cannot be changed after initial assignment')
        end

        it 'allows updating other attributes' do
          opportunity.name = 'Updated Name'

          expect(opportunity).to be_valid
        end
      end

      context 'when opportunity has no candidate pool' do
        it 'allows setting initial candidate pool on new records' do
          opportunity = build(:hmis_ce_opportunity, **opportunity_attributes, candidate_pool: pool1)

          expect(opportunity).to be_valid
        end

        it 'allows setting candidate pool on existing records' do
          opportunity = create(:hmis_ce_opportunity, **opportunity_attributes, candidate_pool: nil)

          opportunity.candidate_pool = pool1
          expect(opportunity).to be_valid
        end
      end
    end
  end
end
