###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisAdmin::AccessControlsController, type: :request do
  let!(:data_source) { create(:hmis_data_source, name: 'HMIS Source') }
  let!(:warehouse_only_data_source) { create(:grda_warehouse_data_source, name: 'Warehouse Only Source', source_type: :sftp) }
  let!(:project) { create(:hmis_hud_project, data_source: data_source) }
  let!(:other_project) { create(:hmis_hud_project, data_source: data_source) }
  let!(:admin_user) { create(:acl_user, first_name: 'Admin', last_name: 'User') }

  before do
    create_access_control(Hmis::User.find(admin_user.id), [])
    create(:hmis_access_control, access_group: create(:hmis_access_group, name: 'Matching Project Collection', with_entities: project))
    create(:hmis_access_control, access_group: create(:hmis_access_group, name: 'Other Project Collection', with_entities: other_project))
    sign_in admin_user
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def row_texts
    page.css('table tbody tr').map { |tr| tr.text.squish }
  end

  it 'lists the filters in table column order' do
    get hmis_admin_access_controls_path
    expect(page.css('form select').map { |s| s['id'] }).to eq(
      [
        'filter_user_group_id', 'filter_user_id', 'filter_role_id', 'filter_access_group_id',
        'filter_data_source_id', 'filter_organization_id', 'filter_project_id', 'filter_coc_code'
      ],
    )
  end

  it 'offers only HMIS data sources' do
    get hmis_admin_access_controls_path
    options = page.css('#filter_data_source_id option').map(&:text)
    expect(options).to include('HMIS Source')
    expect(options).not_to include('Warehouse Only Source')
  end

  it 'offers only organizations in HMIS data sources' do
    create(:grda_warehouse_hud_organization, data_source_id: warehouse_only_data_source.id, OrganizationName: 'Warehouse Only Org')
    get hmis_admin_access_controls_path
    options = page.css('#filter_organization_id option').map(&:text)
    expect(options).to include(project.organization.OrganizationName)
    expect(options).not_to include('Warehouse Only Org')
  end

  it 'offers only CoC codes used by projects in HMIS data sources' do
    create(:hmis_hud_project_coc, data_source: data_source, project: project, CoCCode: 'XX-500')
    create(:hud_project_coc, data_source_id: warehouse_only_data_source.id, CoCCode: 'XX-777')
    get hmis_admin_access_controls_path
    expect(page.css('#filter_coc_code option').map { |o| o['value'] }).to eq(['', 'XX-500'])
  end

  it 'lists only access controls whose collection contains the filtered project' do
    get hmis_admin_access_controls_path, params: { filter: { project_id: project.id } }
    expect(row_texts).to include(a_string_including('Matching Project Collection'))
    expect(row_texts).not_to include(a_string_including('Other Project Collection'))
  end

  it 'lists every access control when the filter is empty' do
    get hmis_admin_access_controls_path, params: { filter: { project_id: '', coc_code: '' } }
    expect(row_texts).to include(
      a_string_including('Matching Project Collection'),
      a_string_including('Other Project Collection'),
    )
  end

  it 'loads only projects in HMIS data sources as project options' do
    warehouse_only_organization = create(:grda_warehouse_hud_organization, data_source_id: warehouse_only_data_source.id)
    warehouse_only_project = create(:grda_warehouse_hud_project, data_source_id: warehouse_only_data_source.id, organization: warehouse_only_organization)
    post project_options_hmis_admin_access_controls_path
    values = page.css('option').map { |o| o['value'].to_i }
    expect(values).to contain_exactly(project.id, other_project.id)
    expect(values).not_to include(warehouse_only_project.id)
  end
end
