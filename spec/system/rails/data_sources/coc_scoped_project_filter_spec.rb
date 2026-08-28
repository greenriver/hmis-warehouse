###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Data source CoC-scoped project table filtering', type: :rails_system do
  include_context 'RailsSystemHelper'

  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_view_projects: true) }
  let!(:collection) { create(:collection) }
  let!(:data_source) { create(:source_data_source) }
  let!(:export) { create(:hud_export, data_source: data_source, ExportID: 'DS1') }
  let!(:org) { create(:hud_organization, data_source: data_source, OrganizationName: 'Alpha Housing') }

  let!(:shelter) do
    create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Emergency Shelter One', ProjectType: 0, confidential: false)
  end
  let!(:confidential_shelter) do
    create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Confidential Emergency Shelter', ProjectType: 0, confidential: true)
  end
  let!(:transitional_housing) do
    create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Transitional Housing One', ProjectType: 2, confidential: false)
  end
  # Two minority-CoC projects purely to keep MA-500 below DataSource::DOMINANT_COC_SHARE (3/5 =
  # 0.6), so the data source requires a CoC choice and renders the filterable coc_scoped_detail
  # page instead of the plain organizations listing (which has no filter controls at all).
  let!(:minority_coc_project_one) do
    create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Minority Coc Project One', ProjectType: 3, confidential: false)
  end
  let!(:minority_coc_project_two) do
    create(:hud_project, data_source: data_source, OrganizationID: org.OrganizationID, ProjectName: 'Minority Coc Project Two', ProjectType: 3, confidential: false)
  end

  before do
    create(:hud_project_coc, project: shelter, ProjectID: shelter.ProjectID, data_source: data_source, CoCCode: 'MA-500')
    create(:hud_project_coc, project: confidential_shelter, ProjectID: confidential_shelter.ProjectID, data_source: data_source, CoCCode: 'MA-500')
    create(:hud_project_coc, project: transitional_housing, ProjectID: transitional_housing.ProjectID, data_source: data_source, CoCCode: 'MA-500')
    create(:hud_project_coc, project: minority_coc_project_one, ProjectID: minority_coc_project_one.ProjectID, data_source: data_source, CoCCode: 'MA-502')
    create(:hud_project_coc, project: minority_coc_project_two, ProjectID: minority_coc_project_two.ProjectID, data_source: data_source, CoCCode: 'MA-502')

    collection.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, role, collection)
  end

  def select2_choose(select_id, option_text)
    find("#select2-#{select_id}-container").click
    find('.select2-results__option', text: option_text, exact_text: true).click
  end

  it 'filters project rows by project type, confidential status, and search text' do
    sign_in_user(user)
    visit data_source_with_coc_code_path(data_source, 'MA-500')

    expect(page).to have_content('Emergency Shelter One')
    expect(page).to have_content('Confidential Project')
    expect(page).to have_content('Transitional Housing One')

    select2_choose('coc_scoped_project_type_filter', 'ES - Entry/Exit')
    expect(page).to have_content('Emergency Shelter One')
    expect(page).to have_content('Confidential Project')
    expect(page).to have_no_content('Transitional Housing One')

    select2_choose('coc_scoped_confidential_filter', 'Confidential')
    expect(page).to have_no_content('Emergency Shelter One')
    expect(page).to have_content('Confidential Project')
    expect(page).to have_no_content('Transitional Housing One')

    select2_choose('coc_scoped_confidential_filter', 'Any')
    select2_choose('coc_scoped_project_type_filter', 'All project types')
    expect(page).to have_content('Emergency Shelter One')
    expect(page).to have_content('Confidential Project')
    expect(page).to have_content('Transitional Housing One')

    fill_in 'coc_scoped_search_filter', with: 'Transitional'
    expect(page).to have_content('Transitional Housing One')
    expect(page).to have_no_content('Emergency Shelter One')
    expect(page).to have_no_content('Confidential Project')

    fill_in 'coc_scoped_search_filter', with: 'no such project exists'
    expect(page).to have_content('No projects found')
    expect(page).to have_no_content('Transitional Housing One')
  end
end
