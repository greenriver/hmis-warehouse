###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
    before { freeze_time }
    after { travel_back }
    let(:today) { Date.current }
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
    let!(:hiv_status_viewer_role) { create :role, can_view_hiv_status: true }

    context 'when user has HIV/AIDS viewing permission' do
      before do
        setup_access_control(user, hiv_status_viewer_role, ds_entity_group)
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

  # Regression coverage for a permission mismatch: these *_options_for_select
  # methods scope through all_project_scope (can_view_assigned_reports), but
  # each underlying model's own options_for_select used to default its
  # internal viewable_by call to :can_view_projects, silently ANDing the two
  # scopes together and returning nothing for a user who only has
  # can_view_assigned_reports (the normal case for HUD report filter forms).
  describe 'options for select scoping for an ACL user with only can_view_assigned_reports' do
    let(:filter) { Filters::FilterBase.new(user_id: user.id) }

    it 'includes the granted data source' do
      expect(filter.data_source_options_for_select(user: user).map(&:last)).to include(data_source.id)
    end

    it 'includes the granted organization' do
      expect(filter.organization_options_for_select(user: user).values.flatten(1).map(&:last)).to include(organization.id)
    end

    it 'includes a project under the granted data source' do
      expect(filter.project_options_for_select(user: user).values.flatten(1).map(&:last)).to include(psh_project.id)
    end

    context 'with a funder on a granted project' do
      let!(:funder) { create :hud_funder, data_source_id: data_source.id, ProjectID: psh_project.ProjectID, Funder: 21 }

      it 'includes the funder' do
        expect(filter.funder_options_for_select(user: user).map(&:last)).to include('21')
      end
    end
  end

  # Regression coverage for the same permission mismatch inside
  # available_coc_codes: a submitted coc_code used to be silently stripped
  # (falling back to blank) for an ACL user granted only
  # can_view_assigned_reports, tripping the "CoC codes can't be blank"
  # validation on report submission even though the code was chosen from the
  # (correctly scoped) coc_codes select.
  describe 'coc_codes filtering for an ACL user with only can_view_assigned_reports' do
    let!(:coc_code_lookup) { create :lookup_coc, coc_code: 'XX-500' }
    let!(:project_coc) { create :hud_project_coc, data_source_id: data_source.id, ProjectID: psh_project.ProjectID, CoCCode: 'XX-500' }

    it 'retains a coc_code inherited from a project viewable via can_view_assigned_reports' do
      filter = Filters::HudFilterBase.new(user_id: user.id).update(coc_codes: ['XX-500'])
      expect(filter.coc_codes).to eq(['XX-500'])
      expect(filter).to be_valid
    end

    it 'still strips a coc_code that is not inherited from any viewable project' do
      filter = Filters::HudFilterBase.new(user_id: user.id).update(coc_codes: ['XX-999'])
      expect(filter.coc_codes).to be_empty
      expect(filter).not_to be_valid
    end
  end

  # Regression coverage: report summaries must agree with both the live
  # "N Projects Included" count on the new-report page
  # (Api::HudFiltersController#index) and the report run itself
  # (HudReports::ReportInstance), which both use effective_project_ids. Two
  # independent summary code paths used to display the raw, un-narrowed
  # project_ids instead: selected_params_for_display (xlsx export summaries)
  # and chosen_projects (the HTML report list page's "Projects:" line, via
  # describe_filter_as_html -> describe -> chosen).
  describe 'selected_params_for_display (xlsx export summaries)' do
    let!(:coc_code_lookup) { create :lookup_coc, coc_code: 'XX-500' }
    let!(:psh_project_coc) { create :hud_project_coc, data_source_id: data_source.id, ProjectID: psh_project.ProjectID, CoCCode: 'XX-500' }

    it 'shows only the CoC-narrowed effective projects, not every raw-picked project' do
      filter = Filters::HudFilterBase.new(user_id: user.id).update(
        project_ids: [psh_project.id, es_project.id],
        coc_codes: ['XX-500'],
      )
      displayed = filter.selected_params_for_display['Projects']
      expect(displayed.any? { |name| name.include?(psh_project.ProjectName) }).to eq(true)
      expect(displayed.any? { |name| name.include?(es_project.ProjectName) }).to eq(false)
    end
  end

  describe 'chosen_projects (the HTML report list page "Projects:" line)' do
    let!(:coc_code_lookup) { create :lookup_coc, coc_code: 'XX-500' }
    let!(:psh_project_coc) { create :hud_project_coc, data_source_id: data_source.id, ProjectID: psh_project.ProjectID, CoCCode: 'XX-500' }

    it 'shows only the CoC-narrowed effective projects, not every raw-picked project' do
      filter = Filters::HudFilterBase.new(user_id: user.id).update(
        project_ids: [psh_project.id, es_project.id],
        coc_codes: ['XX-500'],
      )
      expect(filter.chosen_projects).to include(psh_project.ProjectName)
      expect(filter.chosen_projects).not_to include(es_project.ProjectName)
    end
  end

  describe 'defaults regression' do
    it 'evaluates date defaults at instantiation time (dynamic), not class load time (static)' do
      travel_to Date.new(2025, 1, 1)
      filter1 = Filters::FilterBase.new(user_id: user.id)
      expect(filter1.default_on).to eq(Date.new(2025, 1, 1))

      travel_to Date.new(2025, 1, 15)
      filter2 = Filters::FilterBase.new(user_id: user.id)
      expect(filter2.default_on).to eq(Date.new(2025, 1, 15))

      travel_back
    end
  end
end
