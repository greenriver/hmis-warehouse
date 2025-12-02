###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudPathReport::BaseController, type: :controller do
  # Test through PathsController since BaseController is abstract
  controller(HudPathReport::PathsController) do
  end

  let(:user) { create :acl_user }
  let(:role) { create :role, can_view_assigned_reports: true, can_view_all_hud_reports: true }
  let(:data_source) { create :data_source_fixed_id }
  let(:organization) { create :grda_warehouse_hud_organization }
  let(:config) { create :config }
  let(:site_coc_codes) { ['XX-500'] }
  # We don't actually need the HMIS reports collection as we don't check that for HUD reports yet, but we need A collection.
  let(:all_reports_collection) { Collection.system_collection(:hmis_reports) }

  before do
    Collection.maintain_system_groups
    setup_access_control(user, role, all_reports_collection)
    sign_in user
  end

  describe '#filter' do
    describe 'setting @filter_class' do
      it 'sets @filter_class to PathFilter' do
        get :index
        expect(assigns(:filter_class)).to eq(HudPathReport::Filters::PathFilter)
      end

      it 'creates a filter instance using filter_class' do
        get :index
        expect(assigns(:filter)).to be_a(HudPathReport::Filters::PathFilter)
      end

      it 'sets @filter_class before creating filter instance' do
        get :index
        # @filter_class should be set so views can use it
        expect(assigns(:filter_class)).to be_present
        expect(assigns(:filter)).to be_a(assigns(:filter_class))
      end
    end

    describe 'filter parameter handling' do
      let(:base_filter_params) do
        {
          start: '2023-10-01',
          end: '2024-09-30',
          coc_codes: site_coc_codes,
        }
      end

      context 'when no project_type_codes are provided' do
        it 'accepts empty project_type_codes' do
          filter_params = base_filter_params.merge(project_type_codes: [])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to eq([])
        end

        it 'accepts missing project_type_codes parameter' do
          post :create, params: { filter: base_filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to eq([])
        end
      end

      context 'when a valid PATH project_type_code is provided' do
        it 'accepts "so" as a valid project type code' do
          filter_params = base_filter_params.merge(project_type_codes: ['so'])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to include('so')
        end

        it 'accepts "services_only" as a valid project type code' do
          filter_params = base_filter_params.merge(project_type_codes: ['services_only'])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to include('services_only')
        end
      end

      # The following indicate that the filter accepts a variety of project type codes.
      # In the future, we may want to limit these to valid PATH types, for now these are limited by the form.
      context 'when an invalid project_type_code is provided' do
        it 'accepts non-PATH project type codes but they are not in PATH types' do
          filter_params = base_filter_params.merge(project_type_codes: ['es'])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          # The filter will accept it, but it's not a valid PATH type
          expect(filter.project_type_codes).to include('es')
          expect(filter.path_project_types).not_to include('es')
        end

        it 'accepts "th" as a project type code but it is not a PATH type' do
          filter_params = base_filter_params.merge(project_type_codes: ['th'])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to include('th')
          expect(filter.path_project_types).not_to include('th')
        end

        it 'accepts "ph" as a project type code but it is not a PATH type' do
          filter_params = base_filter_params.merge(project_type_codes: ['ph'])
          post :create, params: { filter: filter_params }
          filter = assigns(:filter)
          expect(filter.project_type_codes).to include('ph')
          expect(filter.path_project_types).not_to include('ph')
        end
      end

      it 'uses update method when filter_params are present' do
        filter_params = base_filter_params.merge(project_type_codes: ['so'])
        post :create, params: { filter: filter_params }
        filter = assigns(:filter)
        expect(filter.start).to eq(Date.parse('2023-10-01'))
        expect(filter.end).to eq(Date.parse('2024-09-30'))
        expect(filter.project_type_codes).to include('so')
      end
    end
  end
end
