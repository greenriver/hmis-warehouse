###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudPathReport::Filters::PathFilter, type: :model do
  let(:user) { create :acl_user }
  let(:filter) { described_class.new(user_id: user.id) }

  describe '#default_project_type_codes' do
    it 'returns an empty array' do
      expect(filter.default_project_type_codes).to eq([])
    end

    it 'does not include any project types by default' do
      expect(filter.default_project_type_codes).to be_empty
    end
  end

  describe '#project_type_code_options_for_select' do
    let(:path_project_types) { filter.path_project_types }

    it 'returns only PATH project types' do
      options = filter.project_type_code_options_for_select
      expect(options.values.map(&:to_sym)).to all(be_in(path_project_types))
    end

    it 'excludes non-PATH project types' do
      all_project_types = HudHelper.util.project_type_group_titles.keys
      non_path_types = all_project_types - path_project_types
      options = filter.project_type_code_options_for_select
      expect(options.keys).not_to include(*non_path_types)
    end

    it 'returns an inverted hash with titles as keys' do
      options = filter.project_type_code_options_for_select
      expect(options).to be_a(Hash)
      # The hash should be inverted (titles as keys, codes as values)
      path_project_types.each do |code|
        matching_title = HudHelper.util.project_type_group_titles[code]
        expect(options).to have_key(matching_title) if matching_title
      end
    end
  end

  describe 'filter behavior with empty default_project_type_codes' do
    it 'does not include any projects when project_type_codes is empty' do
      filter_params = { project_type_codes: [] }
      filter.update(filter_params)
      # This should not include projects based on default project types
      expect(filter.project_type_codes).to eq([])
    end

    it 'requires explicit project type selection' do
      filter_params = {}
      filter.update(filter_params)
      expect(filter.project_type_codes).to eq([])
    end
  end

  describe '#path_project_types' do
    it 'returns the PATH project type codes from HudHelper' do
      expected_types = HudHelper.util.path_project_type_codes
      expect(filter.path_project_types).to eq(expected_types)
    end
  end
end
