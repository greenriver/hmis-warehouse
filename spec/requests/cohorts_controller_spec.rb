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
end
