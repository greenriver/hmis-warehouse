###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/graphql_helpers'

RSpec.describe 'PickList ASSESSMENT_NAMES', type: :request do
  include GraphqlHelpers
  include LoginAndPermissionsSpecHelper

  let!(:ds1) { create(:hmis_primary_data_source) }
  let!(:ds2) { create(:hmis_data_source) }
  let!(:user) { create(:user) }

  let(:query) do
    <<~GRAPHQL
      query GetPickList($pickListType: PickListType!) {
        pickList(pickListType: $pickListType) {
          code
          label
        }
      }
    GRAPHQL
  end

  before { hmis_login(user) }

  def fetch_options
    response, result = post_graphql(pick_list_type: 'ASSESSMENT_NAMES') { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'pickList')
  end

  it 'lists custom assessments in the current data source, with or without rules' do
    ruled = create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'with_rules', title: 'With Rules')
    create(:hmis_form_instance, definition: ruled, data_source: ds1, entity: nil) # applies to all projects
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'legacy_only', title: 'Legacy Only')

    expect(fetch_options).to include(
      { 'code' => 'with_rules', 'label' => 'With Rules' },
      { 'code' => 'legacy_only', 'label' => 'Legacy Only' },
    )
  end

  it 'excludes custom assessments from other data sources and drafts, and does not list other roles as custom' do
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'visible', title: 'Visible')
    create(:hmis_form_definition, data_source: ds2, role: :CUSTOM_ASSESSMENT, identifier: 'other_ds', title: 'Other DS')
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'draft_only', title: 'Draft Only', status: Hmis::Form::Definition::DRAFT)
    create(:hmis_form_definition, data_source: ds1, role: :UPDATE, identifier: 'not_custom', title: 'Not Custom')

    codes = fetch_options.map { |o| o['code'] }
    expect(codes).to include('visible')
    expect(codes).not_to include('other_ds', 'draft_only', 'not_custom')
  end

  it 'uses the latest version title and lists each assessment once' do
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'versioned', title: 'Old Title', version: 1, status: Hmis::Form::Definition::RETIRED)
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'versioned', title: 'New Title', version: 2)

    expect(fetch_options.select { |o| o['code'] == 'versioned' }).to eq([{ 'code' => 'versioned', 'label' => 'New Title' }])
  end

  it 'lists a retired assessment that has no published  and no applicable rules, for legacy data' do
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'retired_only', title: 'Retired Only', status: Hmis::Form::Definition::RETIRED)

    expect(fetch_options).to include({ 'code' => 'retired_only', 'label' => 'Retired Only' })
  end

  it 'lists an assessment with the published title when a newer draft version exists' do
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'being_edited', title: 'Published Title', version: 1)
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'being_edited', title: 'Draft Title', version: 2, status: Hmis::Form::Definition::DRAFT)

    expect(fetch_options.select { |o| o['code'] == 'being_edited' }).to eq([{ 'code' => 'being_edited', 'label' => 'Published Title' }])
  end

  it 'is not affected by a higher version of the same identifier in another data source' do
    create(:hmis_form_definition, data_source: ds1, role: :CUSTOM_ASSESSMENT, identifier: 'shared_id', title: 'DS1 Title', version: 1)
    create(:hmis_form_definition, data_source: ds2, role: :CUSTOM_ASSESSMENT, identifier: 'shared_id', title: 'DS2 Title', version: 5)

    expect(fetch_options.select { |o| o['code'] == 'shared_id' }).to eq([{ 'code' => 'shared_id', 'label' => 'DS1 Title' }])
  end

  it 'always lists HUD assessment stages with HUD labels' do
    options = fetch_options
    expect(options).to include(
      { 'code' => 'INTAKE', 'label' => 'HUD Intake Assessment' },
      { 'code' => 'UPDATE', 'label' => 'HUD Update Assessment' },
      { 'code' => 'ANNUAL', 'label' => 'HUD Annual Assessment' },
      { 'code' => 'EXIT', 'label' => 'HUD Exit Assessment' },
      { 'code' => 'POST_EXIT', 'label' => 'HUD Post exit Assessment' },
    )
    expect(options.map { |o| o['code'] }).not_to include('CUSTOM_ASSESSMENT')
  end
end
