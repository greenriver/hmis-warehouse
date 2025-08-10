# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Rule, type: :model do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: project) }

  describe 'validations' do
    it 'prevents the owner from being changed' do
      new_owner = create(:hmis_hud_project)
      rule.owner = new_owner
      expect(rule).not_to be_valid
      expect(rule.errors[:owner]).to include('cannot be changed')
    end
  end

  describe 'callbacks' do
    let(:builder_instance) { instance_double(Hmis::Ce::Match::CandidatePoolBuilder, perform: true) }

    before do
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:new).and_return(builder_instance)
    end

    it 'calls CandidatePoolBuilder after creation' do
      create(:hmis_ce_priority_scheme, owner: project)
      expect(builder_instance).to have_received(:perform)
    end

    it 'calls CandidatePoolBuilder after destroy' do
      rule.destroy
      expect(builder_instance).to have_received(:perform)
    end

    context 'on update' do
      it 'calls CandidatePoolBuilder if expression changes' do
        rule.update(expression: 'new_expression')
        expect(builder_instance).to have_received(:perform)
      end

      it 'calls CandidatePoolBuilder if rule_type changes' do
        rule.update(rule_type: 'priority_scheme')
        expect(builder_instance).to have_received(:perform)
      end

      it 'calls CandidatePoolBuilder if applicability_config changes' do
        rule.update(applicability_config: { project_types: [1] })
        expect(builder_instance).to have_received(:perform)
      end

      it 'does not call CandidatePoolBuilder if only name changes' do
        rule.update(name: 'New Name')
        expect(builder_instance).not_to have_received(:perform)
      end
    end
  end
end
