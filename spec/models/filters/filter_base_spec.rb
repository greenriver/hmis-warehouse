# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Filters::FilterBase, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:es_project) { create :grda_warehouse_hud_project, ProjectType: 1, OrganizationID: organization.OrganizationID }
  let!(:psh_project) { create :grda_warehouse_hud_project, ProjectType: 3, OrganizationID: organization.OrganizationID }
  let!(:user) { create :acl_user }
  # filter permissions are governed by the projects you can see in the reporting context
  let!(:reporting_role) { create :role, can_view_assigned_reports: true }
  let!(:ds_entity_group) { create :collection }

  before :each do
    ds_entity_group.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, reporting_role, ds_entity_group)
  end

  describe 'FilterBase' do
    it 'defaults to nothing if nothing is specified' do
      filter_params = {}
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'only includes projects if they are included somehow, even if ph is specified' do
      filter_params = {
        project_type_codes: [:ph],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'does not include ES if projects are specified, but includes the specified project' do
      filter_params = {
        project_ids: [psh_project.id],
        project_type_codes: [],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).to include psh_project.id
    end

    it 'does not include any projects if project type codes is empty' do
      filter_params = {
        project_type_codes: [],
      }
      filter = Filters::FilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).not_to include psh_project.id
    end
  end

  describe 'HudFilterBase' do
    it 'HUD filter does not include any projects if nothing is specified' do
      filter_params = {}
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'includes the PSH if type ph is specified' do
      filter_params = {
        project_type_codes: [:ph],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).to include psh_project.id
      expect(filter.effective_project_ids).not_to include es_project.id
    end

    it 'does not include ES if projects are specified, but includes the specified project' do
      filter_params = {
        project_ids: [psh_project.id],
        project_type_codes: [],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).to include psh_project.id
    end

    it 'does not include any projects if project type codes is empty' do
      filter_params = {
        project_type_codes: [],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids).not_to include es_project.id
      expect(filter.effective_project_ids).not_to include psh_project.id
    end

    it 'includes and excludes projects based on operating start and end dates' do
      psh_project.update(OperatingStartDate: '2020-01-01', OperatingEndDate: '2020-02-01')
      es_project.update(OperatingStartDate: '2020-01-01', OperatingEndDate: '2021-01-05')
      filter_params = {
        project_type_codes: [:ph, :es],
      }
      filter = Filters::HudFilterBase.new(user_id: user.id).update(filter_params)
      expect(filter.effective_project_ids_during_range('2021-01-01'.to_date .. '2021-02-01'.to_date)).not_to include psh_project.id
      expect(filter.effective_project_ids_during_range('2021-01-01'.to_date .. '2021-02-01'.to_date)).to include es_project.id
    end
  end

  describe 'date parsing for :on param' do
    let!(:today) { Date.current }
    let(:base) { Filters::FilterBase.new(user_id: user.id) }
    let(:test_date) { Date.new(2025, 4, 27) }

    it 'accepts Date object' do
      expect { base.update(on: test_date) }.not_to raise_error
      expect(base.on).to eq test_date
    end

    it 'accepts US string format' do
      us_str = test_date.strftime('%b %d, %Y')
      expect { base.update(on: us_str) }.not_to raise_error
      expect(base.on).to eq test_date
    end

    it 'accepts ISO string format' do
      iso_str = test_date.strftime('%Y-%m-%d')
      expect { base.update(on: iso_str) }.not_to raise_error
      expect(base.on).to eq test_date
    end

    it 'raises on garbage string' do
      expect { base.update(on: 'notadate') }.to raise_error(ArgumentError)
    end

    it 'raises on slash date string' do
      slash_str = test_date.strftime('%m/%d/%Y')
      expect { base.update(on: slash_str) }.to raise_error(ArgumentError)
    end

    it 'raises on slash ISO date string' do
      slash_iso_str = test_date.strftime('%Y/%m/%d')
      expect { base.update(on: slash_iso_str) }.to raise_error(ArgumentError)
    end

    it 'raises on alternative US date string' do
      alt_us_str = test_date.strftime('%d %b %Y')
      expect { base.update(on: alt_us_str) }.to raise_error(ArgumentError)
    end

    it 'accepts nil' do
      expect { base.update(on: nil) }.not_to raise_error
      expect(base.on).to eq(today)
    end
  end

  describe 'disabilities filtering' do
    let(:filter) { Filters::FilterBase.new(user_id: user.id) }
    let(:hiv_aids_id) { 8 }
    let(:physical_disability_id) { 5 }

    context 'when user has HIV/AIDS viewing permission' do
      before do
        allow(user).to receive(:can_view_hiv_status?).and_return(true)
      end

      it 'includes HIV/AIDS in available disabilities' do
        expect(filter.available_disabilities).to include('HIV/AIDS')
      end

      it 'allows setting HIV/AIDS as a disability filter' do
        filter.update(disabilities: [hiv_aids_id])
        expect(filter.disabilities).to include(hiv_aids_id)
      end

      it 'allows setting multiple disabilities including HIV/AIDS' do
        filter.update(disabilities: [hiv_aids_id, physical_disability_id])
        expect(filter.disabilities).to include(hiv_aids_id, physical_disability_id)
      end
    end

    context 'when user does not have HIV/AIDS viewing permission' do
      before do
        allow(user).to receive(:can_view_hiv_status?).and_return(false)
      end

      it 'excludes HIV/AIDS from available disabilities' do
        expect(filter.available_disabilities).not_to include('HIV/AIDS')
      end

      it 'removes HIV/AIDS from disabilities when set' do
        filter.update(disabilities: [hiv_aids_id])
        expect(filter.disabilities).not_to include(hiv_aids_id)
      end

      it 'keeps other disabilities when HIV/AIDS is included' do
        filter.update(disabilities: [hiv_aids_id, physical_disability_id])
        expect(filter.disabilities).to include(physical_disability_id)
        expect(filter.disabilities).not_to include(hiv_aids_id)
      end
    end
  end
end
