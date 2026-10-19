###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Hud::Project, type: :model do
  include LegacyProjectNamesSetup

  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source, OrganizationName: 'Distinct Org Name') }
  let!(:project) do
    create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Distinct Project Name', confidential: true)
  end
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }

  let(:project_placeholder) { described_class.confidential_project_name }
  let(:organization_placeholder) { GrdaWarehouse::Hud::Organization.confidential_organization_name }
  let(:names_and_view) { LegacyProjectNamesSetup::LEGACY_NAME_ROLES.fetch(:names_and_view) }

  shared_examples 'shows the confidential names' do
    it 'allows the policy to view the name' do
      expect(user.policy_for(project).can_view_name?).to be true
    end

    it 'returns the project and organization names' do
      expect(project.name(user)).to eq 'Distinct Project Name'
      expect(project.organization_name(user)).to eq 'Distinct Org Name'
      expect(project.organization_and_name(user)).to eq 'Distinct Org Name / Distinct Project Name'
    end
  end

  shared_examples 'masks the confidential names' do
    it 'denies the policy the name' do
      expect(user.policy_for(project).can_view_name?).to be false
    end

    it 'returns the placeholders' do
      expect(project.name(user)).to eq project_placeholder
      expect(project.organization_name(user)).to eq organization_placeholder
      expect(project.organization_and_name(user)).to eq project_placeholder
    end
  end

  context 'with a role-based user whose role has names and project view and whose access group has the project' do
    let(:user) { create_legacy_user(names_and_view, [project]) }

    include_examples 'shows the confidential names'

    it 'does not treat the project as confidential for the user' do
      expect(project.confidential_for_user?(user)).to be false
    end
  end

  context 'with a role-based user whose access group has a different project' do
    let(:user) { create_legacy_user(names_and_view, [other_project]) }

    include_examples 'masks the confidential names'

    it 'does not treat the project as confidential for the user, because the role holds the names permission' do
      expect(project.confidential_for_user?(user)).to be false
    end
  end

  context 'with a role-based user whose role has names but not project view' do
    let(:user) { create_legacy_user(LegacyProjectNamesSetup::LEGACY_NAME_ROLES.fetch(:names_only), [project]) }

    include_examples 'masks the confidential names'

    it 'does not treat the project as confidential for the user, because the role holds the names permission' do
      expect(project.confidential_for_user?(user)).to be false
    end
  end

  context 'with a role-based user whose role has project view but not names' do
    let(:user) { create_legacy_user(LegacyProjectNamesSetup::LEGACY_NAME_ROLES.fetch(:view_only), [project]) }

    include_examples 'masks the confidential names'

    it 'treats the project as confidential for the user' do
      expect(project.confidential_for_user?(user)).to be true
    end
  end

  context 'with a role-based user whose access group has the project through its organization' do
    let(:user) { create_legacy_user(names_and_view, [organization]) }

    include_examples 'shows the confidential names'
  end

  context 'with a role-based user whose access group has the project through its data source' do
    let(:user) { create_legacy_user(names_and_view, [data_source]) }

    include_examples 'shows the confidential names'
  end
end
