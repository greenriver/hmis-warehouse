###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Role manager batch update', type: :rails_system do
  include_context 'RailsSystemHelper'

  # Rack's default query parser rejects a body with more than 4,096 params. Each role column posts
  # a hidden field per permission, so this many roles overflows it if every column posts.
  let(:role_count) { (4096 / Role.permissions.count) + 1 }

  let!(:admin_role) { create :admin_role }
  let!(:admin_user) { create :user }
  let!(:roles) { Array.new(role_count) { |i| create :role, name: format('Batch Role %02d', i), can_view_clients: false } }
  let(:hidden_role) { roles.first }
  let(:visible_role) { roles.second }
  let(:untouched_role) { roles.last }

  before do
    admin_user.legacy_roles << admin_role
    sign_in_user(admin_user)
  end

  def toggle_permission(role, permission)
    find("label[for='#{permission}_#{role.id}']").click
  end

  it 'saves changes on a role whose column was hidden again and on a visible role', js: true do
    visit admin_roles_path
    fill_in 'search-roles', with: 'can view clients'

    check "role-toggle-#{hidden_role.id}"
    toggle_permission(hidden_role, :can_view_clients)
    uncheck "role-toggle-#{hidden_role.id}"

    check "role-toggle-#{visible_role.id}"
    toggle_permission(visible_role, :can_view_clients)

    click_button 'Save Changes', match: :first

    expect(page).to have_content('All permissions saved')
    expect(hidden_role.reload.can_view_clients).to be(true)
    expect(visible_role.reload.can_view_clients).to be(true)
    expect(untouched_role.reload.can_view_clients).to be(false)
  end
end
