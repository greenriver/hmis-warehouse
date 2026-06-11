# frozen_string_literal: true

require 'ostruct'
require 'rails_helper'

RSpec.describe Hmis::Filter::CeReferralFilter, type: :model do
  let(:data_source) { create(:hmis_primary_data_source) }

  def apply_filter(scope, project_group_id:)
    input = OpenStruct.new(project_group_id: project_group_id)
    described_class.new(input).filter_scope(scope)
  end

  describe '#filter_scope with project_group_id' do
    let!(:project_in_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_outside_group) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project_group) do
      create(:hmis_project_group, data_source: data_source, with_projects: [project_in_group])
    end

    let!(:referral_in_group) { create(:hmis_ce_referral, data_source: data_source, project: project_in_group) }
    let!(:referral_outside_group) { create(:hmis_ce_referral, data_source: data_source, project: project_outside_group) }
    let(:base_scope) { Hmis::Ce::Referral.where(id: [referral_in_group.id, referral_outside_group.id]) }

    it 'filters referrals to projects in the project group' do
      result = apply_filter(base_scope, project_group_id: project_group.id)
      expect(result).to contain_exactly(referral_in_group)
    end

    it 'returns no rows for an unknown project group' do
      expect(apply_filter(base_scope, project_group_id: -1)).to be_empty
    end
  end

  describe 'assignment filters' do
    let!(:user_a) { create(:hmis_user, data_source: data_source) }
    let!(:user_b) { create(:hmis_user, data_source: data_source) }
    let!(:referral_a) { create(:hmis_ce_referral, data_source: data_source) }
    let!(:referral_b) { create(:hmis_ce_referral, data_source: data_source) }
    let!(:referral_c) { create(:hmis_ce_referral, data_source: data_source) }
    let(:base_scope) { Hmis::Ce::Referral.where(id: [referral_a.id, referral_b.id, referral_c.id]) }

    before do
      create(:hmis_wfe_step, instance: referral_a.workflow_instance, assignees: [user_a])
      create(:hmis_wfe_step, instance: referral_b.workflow_instance, assignees: [user_b])
      create(:hmis_wfe_step, instance: referral_c.workflow_instance, assignees: [user_a], status: 'completed')
    end

    describe '#assigned_to_user' do
      it 'returns referrals with an open step assigned to the given user' do
        input = OpenStruct.new(assigned_to_user: user_a.id)
        result = described_class.new(input).filter_scope(base_scope)
        expect(result).to contain_exactly(referral_a)
      end
    end

    describe '#assigned_to_current_user' do
      it 'returns referrals with an open step assigned to the current user when assigned_to_you is true' do
        input = OpenStruct.new(assigned_to_you: true)
        result = described_class.new(input, user: user_a).filter_scope(base_scope)
        expect(result).to contain_exactly(referral_a)
      end
    end
  end
end
