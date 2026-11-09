###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ColorsController, type: :request do
  include AccessControlSetup

  let!(:user) { create :acl_user }
  let!(:role) { create :role, can_edit_theme: true }
  let!(:collection) { create :collection }
  let!(:race0) { GrdaWarehouse::SystemColor.create!(slug: 'race-0', background_color: '#111111') }
  let!(:race1) { GrdaWarehouse::SystemColor.create!(slug: 'race-1', background_color: '#222222') }

  before do
    setup_access_control(user, role, collection)
    sign_in user
  end

  it 'saves valid colors' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef', 'race-1' => '#ABC' } }

    expect(race0.reload.background_color).to eq('#abcdef')
    expect(race1.reload.background_color).to eq('#ABC')
  end

  it 'saves nothing when any submitted color is invalid' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef', 'race-1' => '#fff}</style><b>x</b>' } }

    expect(response).to redirect_to(edit_admin_color_path)
    expect(race0.reload.background_color).to eq('#111111')
    expect(race1.reload.background_color).to eq('#222222')
  end

  it 'keeps the stored color for a slug the form did not send' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef' } }

    expect(race0.reload.background_color).to eq('#abcdef')
    expect(race1.reload.background_color).to eq('#222222')
  end

  it 'rejects a nested value instead of raising' do
    patch admin_color_path, params: { colors: { 'race-0' => { 'x' => 'y' } } }

    expect(response).to redirect_to(edit_admin_color_path)
    expect(race0.reload.background_color).to eq('#111111')
  end

  it 'denies a user without can_edit_theme' do
    role.update!(can_edit_theme: false)

    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef' } }

    expect(race0.reload.background_color).to eq('#111111')
  end
end
