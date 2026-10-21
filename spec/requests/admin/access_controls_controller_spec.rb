###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AccessControlsController, type: :request do
  include AccessControlSetup

  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization, OrganizationName: 'Open Shelter Org' }
  let!(:project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:other_project) { create :grda_warehouse_hud_project, organization: organization }
  let!(:admin) { create :acl_user }
  let!(:project_collection) { create :collection, name: 'Matching Project Collection' }
  let!(:other_collection) { create :collection, name: 'Other Project Collection' }

  before do
    setup_access_control(admin, create(:role, can_edit_users: true), create(:collection, name: 'Admin Collection'))
    project_collection.set_viewables({ projects: [project.id] })
    other_collection.set_viewables({ projects: [other_project.id] })
    create(:access_control, collection: project_collection, role: create(:role), user_group: create(:user_group))
    create(:access_control, collection: other_collection, role: create(:role), user_group: create(:user_group))
    sign_in admin
  end

  def row_texts
    Nokogiri::HTML(response.body).css('table tbody tr').map { |tr| tr.text.squish }
  end

  it 'lists grant filters in the first column and user and entity filters in the second' do
    get admin_access_controls_path
    columns = Nokogiri::HTML(response.body).css('form .o-filtration__option > div').map { |column| column.css('select').map { |s| s['id'] } }
    expect(columns).to eq(
      [
        ['filter_user_group_id', 'filter_role_id', 'filter_collection_id'],
        ['filter_user_id', 'filter_data_source_id', 'filter_organization_id', 'filter_project_id', 'filter_coc_code'],
      ],
    )
  end

  it 'lists only access controls whose collection contains the filtered project' do
    get admin_access_controls_path, params: { filter: { project_id: project.id } }
    expect(row_texts).to include(a_string_including('Matching Project Collection'))
    expect(row_texts).not_to include(a_string_including('Other Project Collection'))
  end

  it 'loads project options separately, passing the selected project' do
    get admin_access_controls_path, params: { filter: { project_id: project.id } }
    select = Nokogiri::HTML(response.body).at_css('#filter_project_id')
    expect(select.css('option').map { |o| o['value'] }).to eq([''])
    expect(select['data-collection-path']).to eq(project_options_admin_access_controls_path(selected_project_ids: [project.id]))
  end

  describe 'project options' do
    def options
      Nokogiri::HTML(response.body).css('option')
    end

    it 'lists projects the admin has no access to and marks the selected project' do
      post project_options_admin_access_controls_path, params: { selected_project_ids: [project.id.to_s] }
      expect(options.map { |o| o['value'].to_i }).to contain_exactly(project.id, other_project.id)
      expect(options.select { |o| o['selected'] }.map { |o| o['value'].to_i }).to eq([project.id])
    end

    it 'does not list projects for a user who cannot edit users' do
      non_admin = create(:acl_user)
      setup_access_control(non_admin, create(:role, can_view_projects: true), create(:collection))
      sign_in non_admin
      post project_options_admin_access_controls_path
      expect(response).to redirect_to(root_path)
    end

    it 'shows confidential project and organization names to users who cannot view confidential names' do
      confidential_organization = create(:grda_warehouse_hud_organization, OrganizationName: 'Secret Shelter Org', confidential: true)
      confidential_project = create(:grda_warehouse_hud_project, organization: confidential_organization, ProjectName: 'Secret Project', confidential: true)
      post project_options_admin_access_controls_path
      group_labels = Nokogiri::HTML(response.body).css('optgroup').map { |g| g['label'] }
      expect(group_labels).to include(a_string_including('Secret Shelter Org'))
      expect(options.to_h { |o| [o['value'].to_i, o.text] }).to include(confidential_project.id => 'Secret Project')
    end
  end

  describe 'organization options' do
    let!(:confidential_organization) { create(:grda_warehouse_hud_organization, OrganizationName: 'Secret Shelter Org', confidential: true) }

    def organization_option_texts
      Nokogiri::HTML(response.body).css('#filter_organization_id option').to_h { |o| [o['value'].to_i, o.text] }
    end

    it 'shows confidential organization names to users who cannot view confidential names' do
      get admin_access_controls_path
      expect(organization_option_texts).to include(
        confidential_organization.id => 'Secret Shelter Org',
        organization.id => organization.OrganizationName,
      )
    end
  end

  it 'offers CoC codes that a collection lists even when no project uses them' do
    coc_lookup = create(:lookup_coc, coc_code: 'XX-502', official_name: 'Fake CoC 502')
    unused_lookup = create(:lookup_coc, coc_code: 'XX-503', official_name: 'Fake CoC 503')
    create(:collection).set_viewables({ coc_codes: [coc_lookup.id] })
    get admin_access_controls_path
    options = Nokogiri::HTML(response.body).css('#filter_coc_code option').map { |o| o['value'] }
    expect(options).to include('XX-502')
    expect(options).not_to include(unused_lookup.coc_code)
  end

  it 'does not offer CoC codes that only a legacy access group lists' do
    collection_lookup = create(:lookup_coc, coc_code: 'XX-502', official_name: 'Fake CoC 502')
    legacy_lookup = create(:lookup_coc, coc_code: 'XX-504', official_name: 'Fake CoC 504')
    create(:collection).set_viewables({ coc_codes: [collection_lookup.id] })
    GrdaWarehouse::GroupViewableEntity.create!(access_group: create(:access_group), entity: legacy_lookup)
    get admin_access_controls_path
    options = Nokogiri::HTML(response.body).css('#filter_coc_code option').map { |o| o['value'] }
    expect(options).to eq(['', 'XX-502'])
  end

  it 'does not offer a blank CoC code' do
    create(:hud_project_coc, ProjectID: project.ProjectID, data_source_id: data_source.id, CoCCode: '')
    create(:hud_project_coc, ProjectID: other_project.ProjectID, data_source_id: data_source.id, CoCCode: 'XX-600')
    get admin_access_controls_path
    options = Nokogiri::HTML(response.body).css('#filter_coc_code option').map { |o| o['value'] }
    expect(options).to eq(['', 'XX-600'])
  end

  it 'lists every access control when the filter is empty' do
    get admin_access_controls_path, params: { filter: { project_id: '' } }
    expect(row_texts).to include(
      a_string_including('Matching Project Collection'),
      a_string_including('Other Project Collection'),
    )
  end

  describe 'audit history' do
    let(:auditor) { create :acl_user }
    let(:editor) { create :acl_user }

    def history_links
      Nokogiri::HTML(response.body).css("a[href='#{audits_admin_access_controls_path}']")
    end

    before do
      setup_access_control(auditor, create(:role, can_audit_users: true), create(:collection))
      setup_access_control(editor, create(:role, can_edit_users: true), create(:collection))
    end

    it 'shows the history page to a user who can audit users but not edit them' do
      sign_in auditor
      get audits_admin_access_controls_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Access Controls Audit History')
    end

    it 'queues the history render for a user who can audit users but not edit them' do
      sign_in auditor
      expect do
        post render_audits_admin_access_controls_path, params: { render_id: 'history' }
      end.to have_enqueued_job(BackgroundRender::AccessControlsAuditsJob)
    end

    it 'refuses the history page to a user who can edit users but not audit them' do
      sign_in editor
      get audits_admin_access_controls_path
      expect(response).to redirect_to(editor.my_root_path)
    end

    it 'hides the History button from a user who can edit users but not audit them' do
      sign_in editor
      get admin_access_controls_path
      expect(response).to have_http_status(:ok)
      expect(history_links.size).to eq(0)
    end

    it 'shows the History button to a user who can edit and audit users' do
      setup_access_control(editor, create(:role, can_audit_users: true), create(:collection))
      sign_in editor
      get admin_access_controls_path
      expect(history_links.size).to eq(1)
    end
  end
end
