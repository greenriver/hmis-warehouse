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
  let!(:organization) { create :grda_warehouse_hud_organization }
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

  it 'lists the filters in table column order' do
    get admin_access_controls_path
    select_ids = Nokogiri::HTML(response.body).css('form select').map { |s| s['id'] }
    expect(select_ids).to eq(
      [
        'filter_user_group_id', 'filter_user_id', 'filter_role_id', 'filter_collection_id',
        'filter_data_source_id', 'filter_organization_id', 'filter_project_id', 'filter_coc_code'
      ],
    )
  end

  it 'lists only access controls whose collection contains the filtered project' do
    get admin_access_controls_path, params: { filter: { project_id: project.id } }
    expect(row_texts).to include(a_string_including('Matching Project Collection'))
    expect(row_texts).not_to include(a_string_including('Other Project Collection'))
  end

  it 'lists every access control when the filter is empty' do
    get admin_access_controls_path, params: { filter: { project_id: '' } }
    expect(row_texts).to include(
      a_string_including('Matching Project Collection'),
      a_string_including('Other Project Collection'),
    )
  end
end
