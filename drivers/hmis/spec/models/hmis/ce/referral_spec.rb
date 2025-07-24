###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:opportunity) { create(:hmis_ce_opportunity, data_source: data_source) }

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
      referral = build(:hmis_ce_referral, workflow_instance: instance)
      expect(referral.valid?).to be_falsy
      expect do
        referral.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be a CE template/)
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
      let(:workflow_template) { opportunity.workflow_template }
      let!(:workflow_instance) { workflow_template.instances.create! }
      let!(:existing) { create(:hmis_ce_referral, workflow_instance: workflow_instance) }

      it 'does not allow creating a new referral with the same instance' do
        referral = build(:hmis_ce_referral, workflow_instance: workflow_instance)
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
end
