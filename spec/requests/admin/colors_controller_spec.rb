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
  let(:race0) { GrdaWarehouse::SystemColor.find_by!(slug: 'race-0') }
  let(:race1) { GrdaWarehouse::SystemColor.find_by!(slug: 'race-1') }

  before do
    # the edit view renders one field per default slug
    GrdaWarehouse::SystemColor.ensure_colors
    race0.update!(background_color: '#111111')
    race1.update!(background_color: '#222222')
    setup_access_control(user, role, collection)
    sign_in user
  end

  it 'saves valid colors' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef', 'race-1' => '#ABC' } }

    expect(race0.reload.background_color).to eq('#abcdef')
    expect(race1.reload.background_color).to eq('#ABC')
  end

  it 'saves nothing when any submitted color is invalid' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef', 'race-1' => 'red' } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(race0.reload.background_color).to eq('#111111')
    expect(race1.reload.background_color).to eq('#222222')
  end

  it 're-renders the form with the submitted values and names the invalid slug' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef', 'race-1' => 'red' } }

    page = Nokogiri::HTML(response.body)
    expect(page.at_css('input[name="colors[race-0]"]')['value']).to eq('#abcdef')
    expect(page.at_css('input[name="colors[race-1]"]')['value']).to eq('red')
    expect(flash[:error]).to include('race-1')
    expect(flash[:error]).not_to include('race-0')
  end

  it 'keeps the stored color for a slug the form did not send' do
    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef' } }

    expect(race0.reload.background_color).to eq('#abcdef')
    expect(race1.reload.background_color).to eq('#222222')
  end

  it 'rejects a nested value instead of raising' do
    patch admin_color_path, params: { colors: { 'race-0' => { 'x' => 'y' } } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(race0.reload.background_color).to eq('#111111')
  end

  ['colors=%23abcdef', 'colors[]=%23abcdef'].each do |body|
    it "rejects #{body} when colors is not keyed by slug" do
      patch admin_color_path, params: body, headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' }

      expect(response).to redirect_to(edit_admin_color_path)
      expect(flash[:error]).to be_present
      expect(race0.reload.background_color).to eq('#111111')
    end
  end

  it 'denies a user without can_edit_theme' do
    role.update!(can_edit_theme: false)

    patch admin_color_path, params: { colors: { 'race-0' => '#abcdef' } }

    expect(race0.reload.background_color).to eq('#111111')
  end
end
