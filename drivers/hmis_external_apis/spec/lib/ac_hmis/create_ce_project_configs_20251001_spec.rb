###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcHmis::CreateCeProjectConfigs20251001 do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:ce_project) { create(:hmis_hud_project, organization: organization, ProjectName: 'HMIS Coordinated Entry') }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:unit_group1) { create(:hmis_unit_group, project: project) }
  let!(:unit_group2) { create(:hmis_unit_group, project: project) }

  describe '#update_configs (private)' do
    let(:dry) { false }
    subject(:updater) { described_class.new(dry_run: dry) }

    let(:scope) { Hmis::Hud::Project.where(id: project.id) }

    context 'when enabling both waitlist and direct referrals' do
      it 'creates or updates CE config and sets unit groups to housing workflow' do
        updater.send(:update_configs, scope, waitlists: true, direct_referrals: true, label: 'Test', dry_run: dry)

        config = Hmis::ProjectCeConfig.find_by(project_id: project.id)
        expect(config).to be_present
        expect(config.supports_waitlist_referrals?).to be(true)
        expect(config.receives_direct_referrals?).to be(true)
        expect(config.receives_direct_referrals_from).to eq([ce_project.id])

        unit_group1.reload
        unit_group2.reload
        expect(unit_group1.workflow_template_identifier).to eq('housing_workflow_v1')
        expect(unit_group2.workflow_template_identifier).to eq('housing_workflow_v1')
      end
    end

    context 'when enabling direct-only referrals' do
      it 'sets CE config and sets unit groups to admin assign workflow' do
        updater.send(:update_configs, scope, waitlists: false, direct_referrals: true, label: 'Test', dry_run: dry)

        config = Hmis::ProjectCeConfig.find_by(project_id: project.id)
        expect(config).to be_present
        expect(config.supports_waitlist_referrals?).to be(false)
        expect(config.receives_direct_referrals?).to be(true)

        unit_group1.reload
        unit_group2.reload
        expect(unit_group1.workflow_template_identifier).to eq('admin_assign_workflow')
        expect(unit_group2.workflow_template_identifier).to eq('admin_assign_workflow')
      end
    end
  end
end
