###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

# Regression net for the caxlsx_rails template-render path (`format.xlsx` resolving a
# `*.xlsx.axlsx` template), which broke on Rails 8 with caxlsx_rails < 0.7.1 —
# ActionView::MissingTemplate because 0.6.x relied on Rails defaulting the template to
# the action name, behavior Rails 8 removed. Admin::GroupsController#download is a good,
# low-data-dependency exercise of that path: its download.xlsx.axlsx template renders
# header-only worksheets even against empty tables, so a green run here means the
# caxlsx render mechanism itself is working end to end.
RSpec.describe 'Admin::Groups xlsx download', type: :request do
  include AccessControlSetup

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_edit_collections: true) }
  let(:collection) { create(:collection) }

  before do
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  def rendered_workbook
    excel_file = Tempfile.new(['groups_download', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  it 'renders the access-details xlsx workbook via the caxlsx template path' do
    get download_admin_groups_path(format: :xlsx)

    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    workbook = rendered_workbook
    # The template builds a fixed set of worksheets; confirm the workbook parsed and the
    # first ("Users") sheet has its expected header row (proves a real xlsx was rendered,
    # not the action.html fallback that the Rails 8 caxlsx break produced).
    expect(workbook.sheets).to include('Users')
    users_sheet = workbook.sheet('Users')
    expect(users_sheet.row(1)).to eq(
      ['First Name', 'Last Name', 'Email', 'Agency', 'Role', 'Account Created', 'Last Login', 'Active'],
    )
  end

  it 'refuses the download for a user without can_edit_collections' do
    other = create(:acl_user)
    sign_in(other)

    get download_admin_groups_path(format: :xlsx)

    expect(response).not_to have_http_status(:success)
  end
end
