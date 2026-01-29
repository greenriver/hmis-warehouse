###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let!(:project) { create :hmis_hud_project, data_source: data_source }
  let!(:unit) { create(:hmis_unit, project: project) }
  let!(:opportunity) { create(:hmis_ce_opportunity, unit: unit) }

  describe 'Referral model validations' do
    it 'saves an active referral' do
      referral = build(:hmis_ce_referral, opportunity: opportunity, data_source: data_source)
      expect(referral.valid?).to be_truthy
      expect do
        referral.save!
      end.to change(Hmis::Ce::Referral, :count).from(0).to(1)
    end

    it 'does not save a referral with a non-CE template' do
      template = create(:hmis_workflow_definition_template, template_type: 'not_ce')
      instance = create(:hmis_workflow_execution_instance, template: template)
      referral = build(:hmis_ce_referral, workflow_instance: instance, opportunity: opportunity)
      expect(referral.valid?).to be_falsy
      expect do
        referral.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be a CE template/)
    end

    it 'does not save a referral with an invalid status' do
      referral = build(:hmis_ce_referral, status: 'not_a_status', opportunity: opportunity, data_source: data_source)
      expect(referral.valid?).to be_falsy
      expect do
        referral.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /Status must be one of/)
    end

    it 'does not save a referral with an invalid target enrollment in the wrong project' do
      referral = create(:hmis_ce_referral, opportunity: opportunity, data_source: data_source)
      other_enrollment = create(:hmis_hud_enrollment, data_source: data_source, client: referral.client)
      referral.target_enrollment = other_enrollment

      expect(referral.valid?).to be_falsy
      expect do
        referral.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be in same project/)
    end

    ['initialized', 'in_progress', 'accepted'].each do |status|
      context "when there is an existing #{status} referral" do
        let!(:existing) { create(:hmis_ce_referral, opportunity: opportunity, data_source: data_source, status: status) }

        it 'does not allow creating a new active referral' do
          referral = build(:hmis_ce_referral, opportunity: opportunity)
          expect(referral.valid?).to be_falsy
          expect do
            referral.save!
          end.to raise_error(ActiveRecord::RecordInvalid, /can only have one active or accepted referral/).
            and not_change(Hmis::Ce::Referral, :count).from(1)
        end
      end
    end

    context 'when there is an existing referral' do
      let(:workflow_template) { opportunity.unit_group.workflow_template }
      let!(:workflow_instance) { workflow_template.instances.create! }
      let!(:existing) { create(:hmis_ce_referral, workflow_instance: workflow_instance, data_source: data_source) }

      it 'does not allow creating a new referral with the same instance' do
        referral = build(:hmis_ce_referral, workflow_instance: workflow_instance, opportunity: opportunity)
        expect(referral.valid?).to be_falsy
        expect do
          referral.save!
        end.to raise_error(ActiveRecord::RecordInvalid, /Workflow instance has already been taken/).
          and not_change(Hmis::Ce::Referral, :count).from(1)
      end
    end

    context 'when there are several existing rejected referrals' do
      before do
        3.times do
          create(:hmis_ce_referral, opportunity: opportunity, data_source: data_source, status: 'rejected')
        end
      end

      it 'allows creating a new active referral' do
        referral = build(:hmis_ce_referral, opportunity: opportunity, data_source: data_source)
        expect(referral.valid?).to be_truthy
        expect do
          referral.save!
        end.to change(Hmis::Ce::Referral, :count).from(3).to(4)
      end
    end
  end

  describe 'Referral pre-save hooks' do
    describe '#clear_decline_reason_when_accepted' do
      let!(:decline_reason) { create(:ce_referral_decline_reason, data_source: data_source) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: data_source, status: 'in_progress', decline_reason: decline_reason) }

      it 'clears the decline reason when the referral is accepted' do
        expect do
          referral.accept!
        end.to change(referral, :decline_reason).from(decline_reason).to(nil)
      end

      it 'does not clear decline reason when the referral is rejected' do
        expect do
          referral.reject!
        end.not_to change(referral, :decline_reason)
      end
    end
  end

  describe '#create_default_participants!' do
    let!(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: data_source, template_type: 'ce_referral' }
    let!(:unit_group) { create :hmis_unit_group, project: project, workflow_template: template }
    let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group }
    let!(:opportunity) { create :hmis_ce_opportunity, unit: unit }
    let!(:case_manager_1) { create :hmis_user }
    let!(:case_manager_2) { create :hmis_user }
    let!(:provider) { create :hmis_user }
    let!(:case_manager_swimlane) { template.swimlanes.create!(name: 'Case Managers') }
    let!(:provider_swimlane) { template.swimlanes.create!(name: 'Providers') }
    let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, data_source: data_source, workflow_template: template) }

    context 'with assignments at the project level' do
      let!(:default_assignment_1) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: project)
      end
      let!(:default_assignment_2) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_2, swimlane: case_manager_swimlane, owner: project)
      end
      let!(:default_assignment_provider) do
        create(:hmis_ce_default_swimlane_assignment, user: provider, swimlane: provider_swimlane, owner: project)
      end

      it 'creates referral participants from project-level defaults' do
        expect do
          referral.create_default_participants!
        end.to change(Hmis::Ce::ReferralParticipant, :count).by(3)

        expect(referral.participants.pluck(:user_id, :swimlane_id)).to contain_exactly(
          [case_manager_1.id, case_manager_swimlane.id],
          [case_manager_2.id, case_manager_swimlane.id],
          [provider.id, provider_swimlane.id],
        )
      end
    end

    shared_examples 'creates participant from single assignment' do |owner_description|
      it "creates referral participant from #{owner_description}-level default" do
        expect do
          referral.create_default_participants!
        end.to change(Hmis::Ce::ReferralParticipant, :count).by(1)

        participant = referral.participants.first
        expect(participant.user).to eq(case_manager_1)
        expect(participant.swimlane).to eq(case_manager_swimlane)
      end
    end

    context 'with assignment at the unit group level' do
      let!(:default_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: unit_group)
      end

      include_examples 'creates participant from single assignment', 'unit group'
    end

    context 'with assignment at the organization level' do
      let!(:default_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: project.organization)
      end

      include_examples 'creates participant from single assignment', 'organization'
    end

    context 'with assignment at the data source level' do
      let!(:default_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: data_source)
      end

      include_examples 'creates participant from single assignment', 'data source'
    end

    context 'with assignments at multiple levels' do
      let!(:project_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: project)
      end
      let!(:unit_group_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: unit_group)
      end
      let!(:org_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_2, swimlane: case_manager_swimlane, owner: project.organization)
      end
      let!(:ds_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: provider, swimlane: provider_swimlane, owner: data_source)
      end

      it 'creates participants additively from all levels, deduplicating by user and swimlane' do
        expect do
          referral.create_default_participants!
        end.to change(Hmis::Ce::ReferralParticipant, :count).by(3)

        # case_manager_1 assigned from project/unit_group (deduplicated to one participant)
        # case_manager_2 assigned from organization
        # provider assigned from data source with different swimlane
        expect(referral.participants.pluck(:user_id, :swimlane_id)).to contain_exactly(
          [case_manager_1.id, case_manager_swimlane.id],
          [case_manager_2.id, case_manager_swimlane.id],
          [provider.id, provider_swimlane.id],
        )
      end
    end

    context 'with default assignment for an unrelated project' do
      let!(:other_project) { create :hmis_hud_project, data_source: data_source }
      let!(:unrelated_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: other_project)
      end

      it 'does not create participants for unrelated projects' do
        expect do
          referral.create_default_participants!
        end.not_to change(Hmis::Ce::ReferralParticipant, :count)
      end
    end

    context 'with soft-deleted default assignments' do
      let!(:default_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: case_manager_swimlane, owner: project, deleted_at: Time.current)
      end

      it 'does not create participants for soft-deleted assignments' do
        expect do
          referral.create_default_participants!
        end.not_to change(Hmis::Ce::ReferralParticipant, :count)
      end
    end
  end

  describe 'matching_search_term scope' do
    let!(:client1) { create(:hmis_hud_client, data_source: data_source, FirstName: 'Alice', LastName: 'Johnson') }
    let!(:client2) { create(:hmis_hud_client, data_source: data_source, FirstName: 'Bob', LastName: 'Smith') }
    let!(:client3) { create(:hmis_hud_client, data_source: data_source, FirstName: 'Charlie', LastName: 'Johnson') }

    let!(:referral1) { create(:hmis_ce_referral, data_source: data_source, client: client1) }
    let!(:referral2) { create(:hmis_ce_referral, data_source: data_source, client: client2) }
    let!(:referral3) { create(:hmis_ce_referral, data_source: data_source, client: client3) }

    context 'when searching by referral ID' do
      it 'returns the referral with matching ID' do
        scope = Hmis::Ce::Referral.matching_search_term(referral1.id.to_s)
        expect(scope.pluck(:id)).to eq([referral1.id])
      end

      it 'returns nothing if ID does not match' do
        scope = Hmis::Ce::Referral.matching_search_term('999999')
        expect(scope.pluck(:id)).to eq([])
      end
    end

    context 'when searching by client name' do
      it 'returns referrals for clients with matching first name' do
        scope = Hmis::Ce::Referral.matching_search_term('Alice')
        expect(scope.pluck(:id)).to eq([referral1.id])
      end

      it 'returns referrals for clients with matching last name' do
        scope = Hmis::Ce::Referral.matching_search_term('Johnson')
        expect(scope.pluck(:id)).to contain_exactly(referral1.id, referral3.id)
      end

      it 'returns referrals for clients with matching full name' do
        scope = Hmis::Ce::Referral.matching_search_term('Bob Smith')
        expect(scope.pluck(:id)).to eq([referral2.id])
      end

      it 'returns nothing if name does not match' do
        scope = Hmis::Ce::Referral.matching_search_term('Nonexistent')
        expect(scope.pluck(:id)).to eq([])
      end
    end
  end
end
