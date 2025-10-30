# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cohorts#edit', type: :request do
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
          user_ids: [''],
          participant_ids: [''],
          viewer_ids: [''],
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
end
