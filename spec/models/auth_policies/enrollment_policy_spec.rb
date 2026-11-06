###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::EnrollmentPolicy, type: :model do
  let(:data_source) { create :source_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }
  let(:granted_project) { create :grda_warehouse_hud_project, organization: organization, data_source: data_source }
  let(:other_project) { create :grda_warehouse_hud_project, organization: organization, data_source: data_source }
  let(:destination_data_source) { create :destination_data_source }
  let!(:source_client) { create :hud_client, data_source: data_source }
  let!(:destination_client) { create :hud_client, data_source: destination_data_source }
  let!(:warehouse_client) do
    create :warehouse_client, source_id: source_client.id, destination_id: destination_client.id, data_source: data_source
  end
  let!(:granted_enrollment) { create :hud_enrollment, data_source: data_source, client: source_client, project: granted_project }
  let!(:other_enrollment) { create :hud_enrollment, data_source: data_source, client: source_client, project: other_project }

  let(:view_role) { create :role, can_view_clients: true }
  let(:collection) { create :collection }
  let(:user_coc_code) { 'XX-500' }
  let(:user_coc) { create :lookup_coc, coc_code: user_coc_code }

  before do
    GrdaWarehouse::Config.delete_all
    create(:config_b)
    GrdaWarehouse::Config.invalidate_cache
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  # A fresh User per call: policy_for and the arbiter are memoized on the instance.
  def expect_visibility(enrollment, visible, as: user)
    viewer = User.find(as.id)
    expect(
      sql: GrdaWarehouse::Hud::Enrollment.visible_to(viewer).where(id: enrollment.id).exists?,
      policy: viewer.policy_for(enrollment).can_view?,
    ).to eq(sql: visible, policy: visible)
  end

  # For cases where the policy is stricter than the legacy SQL by design.
  def expect_policy_visibility(enrollment, visible, as: user)
    expect(User.find(as.id).policy_for(enrollment).can_view?).to eq(visible)
  end

  def grant_collection(viewables, role: view_role)
    collection.set_viewables(viewables)
    setup_access_control(user, role, collection)
  end

  describe 'ACL' do
    let(:user) { create :acl_user }

    describe 'project grant' do
      it 'shows the enrollment at the granted project and hides the one at the other project' do
        grant_project_access(user, view_role, [granted_project], mode: :acl)
        expect_visibility(granted_enrollment, true)
        expect_visibility(other_enrollment, false)
      end
    end

    describe 'grant on another project' do
      it 'hides the enrollment at the project without a grant' do
        grant_project_access(user, view_role, [other_project], mode: :acl)
        expect_visibility(granted_enrollment, false)
      end
    end

    describe 'permission without can_view_clients' do
      it 'hides the enrollment' do
        grant_project_access(user, create(:role, can_search_own_clients: true), [granted_project], mode: :acl)
        expect_visibility(granted_enrollment, false)
      end
    end

    describe 'organization collection' do
      it 'shows the enrollment' do
        grant_collection({ organizations: [organization.id] })
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'data source collection' do
      it 'shows the enrollment' do
        grant_collection({ data_sources: [data_source.id] })
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'CoC code collection' do
      it 'shows the enrollment at the project in the CoC and hides the other' do
        create :hud_project_coc, data_source: data_source, ProjectID: granted_project.ProjectID, CoCCode: user_coc_code
        grant_collection({ coc_codes: [user_coc.id] })
        expect_visibility(granted_enrollment, true)
        expect_visibility(other_enrollment, false)
      end
    end

    describe 'project access group collection' do
      it 'shows the enrollment at the project in the group and hides the other' do
        project_access_group = create :project_access_group
        project_access_group.projects << granted_project
        grant_collection({ project_access_groups: [project_access_group.id] })
        expect_visibility(granted_enrollment, true)
        expect_visibility(other_enrollment, false)
      end
    end

    describe 'All Data Sources system collection' do
      it 'shows the enrollment' do
        setup_access_control(user, view_role, Collection.system_collection(:data_sources))
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'Window Data Sources system collection' do
      it 'shows the enrollment' do
        data_source.update!(visible_in_window: true)
        Collection.maintain_system_groups(group: :window_data_sources)
        setup_access_control(user, view_role, Collection.system_collection(:window_data_sources))
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'confidential project' do
      it 'shows the enrollment' do
        granted_project.update!(confidential: true)
        grant_project_access(user, view_role, [granted_project], mode: :acl)
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'missing project' do
      it 'hides the enrollment whose ProjectID matches no project' do
        orphan_enrollment = create :hud_enrollment, data_source: data_source, client: source_client, ProjectID: 'no-such-project'
        grant_collection({ data_sources: [data_source.id] })
        expect_visibility(orphan_enrollment, false)
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'missing client' do
      it 'hides the enrollment whose PersonalID matches no client' do
        clientless_enrollment = create :hud_enrollment, data_source: data_source, project: granted_project, PersonalID: 'no-such-client'
        grant_project_access(user, view_role, [granted_project], mode: :acl)
        expect_visibility(clientless_enrollment, false)
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'ROI' do
      let(:roi_role) { create :role, can_view_client_enrollments_with_roi: true }

      def create_roi!
        create :client_roi_authorization, destination_client: destination_client, status: 'full', coc_codes: [user_coc_code]
      end

      def grant_roi_role(project)
        grant_collection({ projects: [project.id], coc_codes: [user_coc.id] }, role: roi_role)
      end

      it 'shows the enrollment with a full release in the user CoC' do
        grant_roi_role(granted_project)
        create_roi!
        expect_visibility(granted_enrollment, true)
      end

      it 'hides the enrollment without an ROI' do
        grant_roi_role(granted_project)
        expect_visibility(granted_enrollment, false)
      end

      it 'hides the enrollment at a project the ROI role does not cover' do
        grant_roi_role(other_project)
        create_roi!
        expect_visibility(granted_enrollment, false)
        expect_visibility(other_enrollment, true)
      end

      it 'hides the enrollment when the data source does not obey consent' do
        grant_roi_role(granted_project)
        create_roi!
        data_source.update!(obey_consent: false)
        expect_visibility(granted_enrollment, false)
      end
    end
  end

  describe 'Legacy' do
    let(:legacy_role) { create :role, can_view_clients: true }
    let(:user) { create(:user).tap { |legacy_user| legacy_role.add(legacy_user) } }

    def stub_window_requires_release(value)
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:window_access_requires_release).and_return(value)
    end

    describe 'access group with the project' do
      it 'shows the enrollment at the project and hides the one at the other project' do
        grant_project_access(user, legacy_role, [granted_project], mode: :legacy)
        expect_visibility(granted_enrollment, true)
        expect_visibility(other_enrollment, false)
      end
    end

    describe 'missing client' do
      it 'hides the enrollment whose PersonalID matches no client' do
        clientless_enrollment = create :hud_enrollment, data_source: data_source, project: granted_project, PersonalID: 'no-such-client'
        grant_project_access(user, legacy_role, [granted_project], mode: :legacy)
        expect_policy_visibility(clientless_enrollment, false)
        expect_policy_visibility(granted_enrollment, true)
      end
    end

    describe 'access group with the data source' do
      it 'shows the enrollment' do
        access_group = create :access_group
        access_group.add(user)
        access_group.add_viewable(data_source)
        expect_visibility(granted_enrollment, true)
      end
    end

    describe 'window data source' do
      before { data_source.update!(visible_in_window: true) }

      it 'shows the enrollment when window access does not require a release' do
        stub_window_requires_release(false)
        expect_visibility(granted_enrollment, true)
      end

      it 'hides the enrollment when window access requires a release and the client has none' do
        stub_window_requires_release(true)
        expect_visibility(granted_enrollment, false)
      end
    end

    describe 'consent without project access' do
      before do
        user.coc_codes = [user_coc_code]
        destination_client.update_columns(
          housing_release_status: GrdaWarehouse::Hud::Client.full_release_string,
          consent_form_signed_on: Date.current,
          consented_coc_codes: [user_coc_code],
        )
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
      end

      it 'shows the enrollment when the client has a full release in the user CoC' do
        expect_visibility(granted_enrollment, true)
      end

      it 'hides the enrollment whose ProjectID matches no project' do
        orphan_enrollment = create :hud_enrollment, data_source: data_source, client: source_client, ProjectID: 'no-such-project'
        expect_policy_visibility(orphan_enrollment, false)
        expect_policy_visibility(granted_enrollment, true)
      end

      it 'hides the enrollment when the consent is for a CoC the user does not have' do
        destination_client.update_columns(consented_coc_codes: ['XX-999'])
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
        expect_visibility(granted_enrollment, false)
      end

      it 'hides the enrollment when the consent has expired' do
        GrdaWarehouse::Config.first.update!(release_duration: 'Use Expiration Date')
        GrdaWarehouse::Config.invalidate_cache
        destination_client.update_columns(consent_expires_on: Date.current - 1.day)
        GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask.new._perform(client_ids: [destination_client.id])
        expect_visibility(granted_enrollment, false)
      end
    end

    describe 'no grant' do
      it 'hides the enrollment' do
        expect_visibility(granted_enrollment, false)
      end
    end
  end
end
