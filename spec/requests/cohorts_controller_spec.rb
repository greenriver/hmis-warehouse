###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortsController, type: :request do
  describe 'GET /cohorts/:id/edit' do
    let(:user) { create(:acl_user) }
    let(:cohort) { create(:cohort) }
    let(:cohort_role) { create(:cohort_manager) }
    let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

    before do
      Collection.maintain_system_groups
      setup_access_control(user, cohort_role, all_cohorts_collection)
      allow(CasAccess::Tag).to receive(:available_cohort_tags).and_return([])
      sign_in user
    end

    it 'renders the edit page' do
      get edit_cohort_path(cohort)

      expect(response).to be_successful
      expect(response.body).to include('Automation')
    end
  end

  describe 'PATCH /cohorts/:id' do
    let(:user) { create(:acl_user) }
    let(:cohort) { create(:cohort, project_group: project_group, automation_sub_population: nil, automation_hoh_only: false) }
    let(:project_group) { create(:project_group) }
    let(:cohort_role) { create(:cohort_manager) }
    let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

    before do
      Collection.maintain_system_groups
      setup_access_control(user, cohort_role, all_cohorts_collection)
      allow(CasAccess::Tag).to receive(:available_cohort_tags).and_return([])
      sign_in user
    end

    it 'updates automation settings when project group is present' do
      patch cohort_path(cohort), params: {
        cohort: {
          project_group_id: project_group.id,
          automation_hoh_only: '1',
          automation_sub_population: 'veterans',
          days_of_inactivity: cohort.days_of_inactivity,
          static_column_count: cohort.static_column_count,
          user_ids: [],
          participant_ids: [],
          viewer_ids: [],
        },
      }

      expect(response).to redirect_to(cohort_path(cohort))
      cohort.reload
      expect(cohort.project_group).to eq(project_group)
      expect(cohort.automation_sub_population).to eq('veterans')
      expect(cohort.automation_hoh_only).to be(true)
    end

    it 'clears automation settings when project group removed' do
      patch cohort_path(cohort), params: {
        cohort: {
          project_group_id: '',
          automation_sub_population: 'veterans',
          automation_hoh_only: '1',
          user_ids: [''],
          participant_ids: [''],
          viewer_ids: [''],
        },
      }

      cohort.reload
      expect(cohort.project_group).to be_nil
      expect(cohort.automation_sub_population).to be_nil
      expect(cohort.automation_hoh_only).to be(false)
    end
  end

  describe 'POST /cohorts/:id/maintain' do
    let(:user) { create(:acl_user) }
    let(:project_group) { create(:project_group) }
    let(:auto_cohort) { create(:cohort, project_group: project_group) }
    let(:manual_cohort) { create(:cohort) }
    let(:cohort_role) { create(:cohort_manager) }
    let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

    before do
      Collection.maintain_system_groups
      setup_access_control(user, cohort_role, all_cohorts_collection)
      sign_in user
      Delayed::Job.delete_all
    end

    after { Delayed::Job.delete_all }

    it 'runs maintenance for automated cohorts' do
      expect do
        post maintain_cohort_path(auto_cohort)
      end.to change(Delayed::Job, :count).by(1)

      expect(response).to redirect_to(cohort_path(auto_cohort))
      expect(flash[:notice]).to eq('Cohort maintenance queued.')
    end

    it 'alerts when cohort is manual' do
      expect do
        post maintain_cohort_path(manual_cohort)
      end.not_to change(Delayed::Job, :count)

      expect(response).to redirect_to(cohort_path(manual_cohort))
      expect(flash[:alert]).to eq('This cohort is manually maintained.')
    end
  end

  describe 'DELETE /cohorts/:id' do
    let(:user) { create(:acl_user) }
    let(:cohort) { create(:cohort) }
    let(:cohort_role) { create(:cohort_manager) }
    let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

    before do
      Collection.maintain_system_groups
      setup_access_control(user, cohort_role, all_cohorts_collection)
      sign_in user
    end

    it "removes the cohort's system collection when the cohort is deleted" do
      collection = cohort.viewable_access_control.collection

      delete cohort_path(cohort)

      expect(GrdaWarehouse::Cohort.find_by(id: cohort.id)).to be_nil
      expect(Collection.find_by(id: collection.id)).to be_nil
    end

    it 'does not delete a system cohort' do
      system_cohort = create(:cohort, system_cohort: true)

      delete cohort_path(system_cohort)

      expect(GrdaWarehouse::Cohort.find_by(id: system_cohort.id)).to be_present
    end
  end

  describe 'per-cohort authorization' do
    let(:user) { create(:acl_user) }
    let(:cohort) { create(:cohort, name: 'Target cohort') }
    let(:other_cohort) { create(:cohort, name: 'Other cohort') }

    before do
      Collection.maintain_system_groups
      allow(CasAccess::Tag).to receive(:available_cohort_tags).and_return([])
    end

    def role_with(*permissions)
      create(:role, **permissions.index_with { true })
    end

    def grant_acl(user, permissions, *records)
      collection = create(:collection)
      collection.set_viewables({ cohorts: records.map(&:id) })
      setup_access_control(user, role_with(*permissions), collection)
    end

    def grant_legacy(user, permissions, *records)
      access_group = create(:access_group)
      role_with(*permissions).add(user)
      access_group.add(user)
      records.each { |record| access_group.add_viewable(record) }
    end

    def create_default_tabs(cohort)
      GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create!(**rule) }
    end

    def refused?
      response.redirect? && !response.location.include?('/cohorts/')
    end

    shared_examples 'cohort access by mode' do
      before { sign_in user }

      it 'lets a manager-only user edit, update, maintain and destroy but not show' do
        grant(user, [:can_configure_cohorts], cohort)

        get cohort_path(cohort)
        expect(response).to redirect_to(user.my_root_path)
        expect(response.body).not_to include(cohort.name)

        get edit_cohort_path(cohort)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(cohort.name)

        patch cohort_path(cohort), params: { cohort: { name: 'Renamed by manager' } }
        expect(cohort.reload.name).to eq('Renamed by manager')

        post maintain_cohort_path(cohort)
        expect(response).to redirect_to(edit_cohort_path(cohort))

        delete cohort_path(cohort)
        expect(GrdaWarehouse::Cohort.find_by(id: cohort.id)).to be_nil
      end

      it 'renders show for a user who can view the cohort' do
        GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create(**rule) }
        grant(user, [:can_view_cohorts], cohort)

        get cohort_path(cohort)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(cohort.name)
      end

      it 'refuses edit and update to a user who can only view the cohort' do
        grant(user, [:can_view_cohorts], cohort)
        original_name = cohort.name

        get edit_cohort_path(cohort)
        expect(response).to redirect_to(user.my_root_path)

        patch cohort_path(cohort), params: { cohort: { name: 'Hijacked' } }
        expect(cohort.reload.name).to eq(original_name)
      end

      it 'refuses edit, maintain and destroy on a cohort the configure permission was not granted on' do
        grant(user, [:can_configure_cohorts], cohort)

        get edit_cohort_path(other_cohort)
        expect(response).to redirect_to(user.my_root_path)
        expect(response.body).not_to include(other_cohort.name)

        post maintain_cohort_path(other_cohort)
        expect(response).to redirect_to(user.my_root_path)

        delete cohort_path(other_cohort)
        expect(response).to redirect_to(user.my_root_path)
        expect(GrdaWarehouse::Cohort.exists?(other_cohort.id)).to be(true)
      end

      it 'refuses show on a cohort the view permission was not granted on' do
        GrdaWarehouse::CohortTab.default_rules.each { |rule| other_cohort.cohort_tabs.create(**rule) }
        grant(user, [:can_view_cohorts], cohort)

        get cohort_path(other_cohort)

        expect(response).to redirect_to(user.my_root_path)
        expect(response.body).not_to include(other_cohort.name)
      end

      it 'creates no access records when edit is refused' do
        grant(user, [:can_view_cohorts], cohort)
        counts = -> { [UserGroup.count, AccessControl.count] }
        before_counts = counts.call

        get edit_cohort_path(cohort)

        expect(counts.call).to eq(before_counts)
      end

      it 'refuses new and create to a user without can_create_cohorts' do
        grant(user, [:can_configure_cohorts, :can_view_cohorts], cohort)

        get new_cohort_path
        expect(response).to redirect_to(user.my_root_path)

        expect do
          post cohorts_path, params: { cohort: { name: 'Sneaky cohort' } }
        end.not_to change(GrdaWarehouse::Cohort, :count)
      end

      it 'renders the grid edit form for a user who can view and manage inactive clients' do
        grant(user, [:can_view_cohorts, :can_manage_inactive_cohort_clients], cohort)
        create_default_tabs(cohort)

        get cohort_path(cohort)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="edit_cohort_client"')
      end

      it 'does not render the grid edit form for a view-only user' do
        grant(user, [:can_view_cohorts], cohort)
        create_default_tabs(cohort)

        get cohort_path(cohort)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('edit_cohort_client')
      end
    end

    context 'with an ACL user' do
      def grant(...) = grant_acl(...)

      include_examples 'cohort access by mode'

      describe 'GET /cohorts' do
        before { sign_in user }

        it 'lists view, participate and manager-only cohorts and hides unrelated ones' do
          viewed = create(:cohort, name: 'Viewed cohort')
          participated = create(:cohort, name: 'Participated cohort')
          managed = create(:cohort, name: 'Managed cohort')
          unrelated = create(:cohort, name: 'Unrelated cohort')
          grant_acl(user, [:can_view_cohorts], viewed)
          grant_acl(user, [:can_participate_in_cohorts, :can_view_cohorts], participated)
          grant_acl(user, [:can_configure_cohorts], managed)

          get cohorts_path

          expect(response.body).to include(%(href="#{cohort_path(viewed)}"), %(href="#{cohort_path(participated)}"))
          expect(response.body).to include(%(href="#{edit_cohort_path(managed)}"))
          expect(response.body).not_to include(%(href="#{cohort_path(managed)}"))
          expect(response.body).not_to include(unrelated.name)
        end

        it 'lists inactive cohorts only where the user can configure them' do
          configurable = create(:cohort, name: 'Inactive managed', active_cohort: false)
          view_only = create(:cohort, name: 'Inactive viewed', active_cohort: false)
          grant_acl(user, [:can_configure_cohorts], configurable)
          grant_acl(user, [:can_view_cohorts], view_only)

          get cohorts_path

          expect(response.body).to include(configurable.name)
          expect(response.body).not_to include(view_only.name)
        end

        it 'matches a client id only on cohorts the user can view' do
          client = create(:grda_warehouse_hud_client)
          managed = create(:cohort, name: 'Managed with client')
          viewed = create(:cohort, name: 'Viewed with client')
          [managed, viewed].each { |c| create(:cohort_client, cohort_id: c.id, client_id: client.id) }
          grant_acl(user, [:can_configure_cohorts], managed)
          grant_acl(user, [:can_view_cohorts], viewed)

          get cohorts_path('search_form[q]' => client.id.to_s)

          expect(response.body).to include(viewed.name)
          expect(response.body).not_to include(managed.name)
        end

        it 'shows Add Cohort only with can_create_cohorts' do
          grant_acl(user, [:can_view_cohorts], cohort)
          get cohorts_path
          expect(response.body).not_to include(new_cohort_path)

          grant_acl(user, [:can_create_cohorts], cohort)
          get cohorts_path
          expect(response.body).to include(new_cohort_path)
        end
      end

      describe 'GET /cohorts/new' do
        before do
          sign_in user
          grant_acl(user, [:can_create_cohorts, :can_view_cohorts], cohort)
        end

        it 'renders manager, participant and viewer pickers with the current user selected' do
          get new_cohort_path

          expect(response).to have_http_status(:ok)
          html = Nokogiri::HTML(response.body)
          [:manager_ids, :participant_ids, :viewer_ids].each do |field|
            selected = html.css("select[name='cohort[#{field}][]'] option[selected]").map { |o| o['value'] }
            expect(selected).to eq([user.id.to_s]), "#{field} preselection"
          end
        end
      end

      describe 'POST /cohorts' do
        before do
          sign_in user
          grant_acl(user, [:can_create_cohorts, :can_view_cohorts], cohort)
        end

        def group_user_ids(created, scope)
          case scope
          when :manager then created.manager_user_ids
          when :editor then created.editable_access_control.user_ids
          when :viewer then created.viewable_access_control.user_ids
          end
        end

        it 'makes the creator manager, participant and viewer with the form defaults' do
          post cohorts_path, params: { cohort: { name: 'Fresh cohort', manager_ids: ['', user.id], participant_ids: ['', user.id], viewer_ids: ['', user.id] } }

          created = GrdaWarehouse::Cohort.find_by!(name: 'Fresh cohort')
          [:manager, :editor, :viewer].each do |scope|
            expect(group_user_ids(created, scope)).to eq([user.id]), "#{scope} members"
          end
        end

        it 'makes only the submitted manager a manager' do
          other = create(:acl_user)

          post cohorts_path, params: { cohort: { name: 'Handed off', manager_ids: [other.id], participant_ids: [''], viewer_ids: [''] } }

          created = GrdaWarehouse::Cohort.find_by!(name: 'Handed off')
          expect(created.manager_user_ids).to eq([other.id])
          expect(created.editable_access_control.user_ids).to be_empty
          expect(created.viewable_access_control.user_ids).to be_empty
        end

        it 'ignores ids that are not active users' do
          inactive = create(:acl_user, active: false)

          post cohorts_path, params: { cohort: { name: 'Ignoring ids', manager_ids: [inactive.id, 0] } }

          expect(GrdaWarehouse::Cohort.find_by!(name: 'Ignoring ids').manager_user_ids).to be_empty
        end
      end

      describe 'PATCH /cohorts/:id' do
        let(:manager) { create(:acl_user) }
        let(:viewer) { create(:acl_user) }

        before do
          sign_in user
          grant_acl(user, [:can_configure_cohorts, :can_view_cohorts], cohort)
          cohort.replace_access([manager], scope: :manager)
          cohort.replace_access([viewer], scope: :viewer)
        end

        it 'rolls back every access list and the cohort when a later step fails' do
          participant = create(:acl_user)
          allow_any_instance_of(GrdaWarehouse::Cohort).to receive(:rename_manager_group).and_raise(ActiveRecord::RecordInvalid)

          begin
            patch cohort_path(cohort), params: { cohort: { name: 'Half applied', manager_ids: [''], viewer_ids: [''], participant_ids: [participant.id] } }
          rescue ActiveRecord::RecordInvalid
            nil
          end

          fresh = GrdaWarehouse::Cohort.find(cohort.id)
          expect(fresh.name).to eq(cohort.name)
          expect(fresh.manager_user_ids).to eq([manager.id])
          expect(fresh.viewable_access_control.user_ids).to eq([viewer.id])
          expect(fresh.editable_access_control.user_ids).to be_empty
        end

        it 'removes all managers when manager_ids is empty' do
          patch cohort_path(cohort), params: { cohort: { manager_ids: [''] } }

          expect(GrdaWarehouse::Cohort.find(cohort.id).manager_user_ids).to be_empty
          expect(GrdaWarehouse::Cohort.find(cohort.id).viewable_access_control.user_ids).to eq([viewer.id])
        end

        it 'leaves a group alone when its key is absent' do
          patch cohort_path(cohort), params: { cohort: { viewer_ids: [''] } }

          fresh = GrdaWarehouse::Cohort.find(cohort.id)
          expect(fresh.manager_user_ids).to eq([manager.id])
          expect(fresh.viewable_access_control.user_ids).to be_empty
        end

        it 'changes no group when the update is invalid' do
          patch cohort_path(cohort), params: { cohort: { name: '', manager_ids: [''], viewer_ids: [''], participant_ids: [user.id] } }

          fresh = GrdaWarehouse::Cohort.find(cohort.id)
          expect(fresh.manager_user_ids).to eq([manager.id])
          expect(fresh.viewable_access_control.user_ids).to eq([viewer.id])
          expect(fresh.editable_access_control.user_ids).to be_empty
        end

        it 'renames the manager group with the cohort' do
          patch cohort_path(cohort), params: { cohort: { name: 'Brand new name' } }

          expect(UserGroup.system.find_by(source: cohort, context: :manager).name).to include('Brand new name')
        end

        it 'redirects to the cohort when the user can still view it' do
          patch cohort_path(cohort), params: { cohort: { name: 'Same access' } }

          expect(response).to redirect_to(cohort_path(cohort))
        end
      end
    end

    context 'with an ACL manager-only user' do
      let(:user) { create(:acl_user) }

      it 'redirects to the cohorts list after the user removes their own manager access' do
        cohort.replace_access([user], scope: :manager)
        sign_in user

        patch cohort_path(cohort), params: { cohort: { manager_ids: [''] } }

        expect(GrdaWarehouse::Cohort.find(cohort.id).manager_user_ids).to be_empty
        expect(response).to redirect_to(cohorts_path)
      end

      it 'redirects to the edit page while the user remains a manager without view access' do
        cohort.replace_access([user], scope: :manager)
        sign_in user

        patch cohort_path(cohort), params: { cohort: { name: 'Still managed' } }

        expect(response).to redirect_to(edit_cohort_path(cohort))
      end
    end

    context 'with a legacy user' do
      let(:user) { create(:user) }

      def grant(...) = grant_legacy(...)

      include_examples 'cohort access by mode'
    end
  end
end
