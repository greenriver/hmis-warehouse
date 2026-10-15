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

  it 'lists only access controls whose collection contains the filtered project' do
    get hmis_admin_access_controls_path, params: { filter: { project_id: project.id } }
    expect(row_texts).to include(a_string_including('Matching Project Collection'))
    expect(row_texts).not_to include(a_string_including('Other Project Collection'))
  end
end
