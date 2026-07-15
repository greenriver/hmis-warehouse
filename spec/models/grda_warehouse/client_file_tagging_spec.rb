###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for the acts-as-taggable-on behaviors the app depends on, pinned
# so a gem major bump (e.g. 12 -> 13 for Rails 8.1) can't silently break them. The
# `.tagged_with` query path in particular is what CAS eligibility keys off of (see
# GrdaWarehouse::Concerns / cas_client_data.rb#sync_cas_attributes_with_files, which
# calls `client_files.tagged_with(names, any: true).exists?`) yet was previously
# untested at the model level.
RSpec.describe GrdaWarehouse::ClientFile, 'acts-as-taggable-on tagging', type: :model do
  let!(:client) { create :grda_warehouse_hud_client }
  let!(:bha_tag) { create :available_file_tag, name: 'BHA Eligibility' }
  let!(:other_tag) { create :available_file_tag, name: 'Other Tag' }

  let!(:bha_file) { create :client_file, client: client, tags: [bha_tag] }
  let!(:other_file) { create :client_file, client: client, tags: [other_tag] }
  let!(:untagged_file) { create :client_file, client: client }

  describe 'tag assignment round-trip' do
    it 'persists the assigned tag and reflects it in tag_list after reload' do
      expect(bha_file.reload.tag_list).to include('BHA Eligibility')
    end

    it 'leaves untagged files with an empty tag_list' do
      expect(untagged_file.reload.tag_list).to be_empty
    end
  end

  describe '.tagged_with (the CAS-eligibility query path)' do
    it 'returns only the files carrying the given tag' do
      result = described_class.tagged_with('BHA Eligibility')

      expect(result).to include(bha_file)
      expect(result).not_to include(other_file)
      expect(result).not_to include(untagged_file)
    end

    it 'matches any of several tag names with any: true, as sync_cas_attributes_with_files does' do
      result = described_class.tagged_with(['BHA Eligibility', 'Nonexistent Tag'], any: true)

      expect(result).to include(bha_file)
      expect(result).not_to include(other_file)
      expect(result).not_to include(untagged_file)
    end

    it 'works when chained off an association (client.client_files.tagged_with(...).exists?)' do
      expect(client.client_files.tagged_with('BHA Eligibility', any: true).exists?).to be(true)
      expect(client.client_files.tagged_with('Other Tag', any: true).exists?).to be(true)
      expect(client.client_files.tagged_with('Never Applied', any: true).exists?).to be(false)
    end
  end
end
