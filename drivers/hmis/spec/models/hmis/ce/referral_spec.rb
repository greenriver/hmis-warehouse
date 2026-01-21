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
      context 'with allow_name_search: true' do
        it 'returns referrals for clients with matching first name' do
          scope = Hmis::Ce::Referral.matching_search_term('Alice', allow_name_search: true)
          expect(scope.pluck(:id)).to eq([referral1.id])
        end

        it 'returns referrals for clients with matching last name' do
          scope = Hmis::Ce::Referral.matching_search_term('Johnson', allow_name_search: true)
          expect(scope.pluck(:id)).to contain_exactly(referral1.id, referral3.id)
        end

        it 'returns referrals for clients with matching full name' do
          scope = Hmis::Ce::Referral.matching_search_term('Bob Smith', allow_name_search: true)
          expect(scope.pluck(:id)).to eq([referral2.id])
        end

        it 'returns nothing if name does not match' do
          scope = Hmis::Ce::Referral.matching_search_term('Nonexistent', allow_name_search: true)
          expect(scope.pluck(:id)).to eq([])
        end
      end

      context 'with allow_name_search: false' do
        it 'returns nothing when searching by name' do
          scope = Hmis::Ce::Referral.matching_search_term('Alice', allow_name_search: false)
          expect(scope.pluck(:id)).to eq([])
        end

        it 'still returns referrals when searching by ID' do
          scope = Hmis::Ce::Referral.matching_search_term(referral1.id.to_s, allow_name_search: false)
          expect(scope.pluck(:id)).to eq([referral1.id])
        end
      end
    end
  end
end
