###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Regression coverage for acts-as-taggable-on on Hmis::File, pinned so a gem major bump
# (12 -> 13 for Rails 8.1) can't silently break it. Unlike warehouse ClientFiles (tagged
# by name), HMIS tags files by AvailableFileTag id (see file_processor.rb and the
# HmisSchema::File `tags` resolver, which returns `object.tags.map(&:id)`).
RSpec.describe Hmis::File, type: :model do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  before(:all) { cleanup_test_environment }
  after(:all) { cleanup_test_environment }

  let!(:birth_cert_file) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag] }
  let!(:ssn_file) { create :file, client: c1, blob: blob, user: hmis_user, tags: [tag2] }
  let!(:untagged_file) { create :file, client: c1, blob: blob, user: hmis_user }

  describe 'tag assignment + #tags resolution (Hmis::File#tags / tag_list)' do
    it 'stores the AvailableFileTag id in tag_list and resolves it back via #tags' do
      expect(birth_cert_file.reload.tag_list).to include(tag.id.to_s)
      expect(birth_cert_file.tags).to include(tag)
      expect(birth_cert_file.tags).not_to include(tag2)
    end

    it 'leaves untagged files with an empty tag_list and no resolved tags' do
      expect(untagged_file.reload.tag_list).to be_empty
      expect(untagged_file.tags).to be_empty
    end
  end

  describe '.tagged_with' do
    it 'returns only files carrying the given tag' do
      result = described_class.tagged_with(tag.id.to_s)

      expect(result).to include(birth_cert_file)
      expect(result).not_to include(ssn_file)
      expect(result).not_to include(untagged_file)
    end

    it 'matches any of several tag values with any: true' do
      result = described_class.tagged_with([tag.id.to_s, tag2.id.to_s], any: true)

      expect(result).to include(birth_cert_file)
      expect(result).to include(ssn_file)
      expect(result).not_to include(untagged_file)
    end

    # Hmis::File shares the `files` table (STI) with warehouse File subclasses, and
    # taggings.taggable_type is the base 'GrdaWarehouse::File' for all of them. HMIS tags by
    # AvailableFileTag id while warehouse tags by name, so a warehouse file could carry a
    # name string equal to an HMIS tag's id. Pin that STI `type` still isolates the results
    # (every other negative in this file is a same-class Hmis::File row).
    it 'excludes a differently-typed warehouse file carrying the same tag value' do
      foreign = GrdaWarehouse::PublicFile.new(name: 'Public thing')
      foreign.tag_list = [tag.id.to_s]
      foreign.save!(validate: false)

      result = described_class.tagged_with(tag.id.to_s)

      expect(result.map(&:id)).to include(birth_cert_file.id)
      expect(result.map(&:id)).not_to include(foreign.id)
    end
  end
end
