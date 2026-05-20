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
end
