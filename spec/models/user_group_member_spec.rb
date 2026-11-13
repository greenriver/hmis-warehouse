###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupMember, type: :model do
  describe '.describe_changes' do
    # PaperTrail is globally disabled in tests for performance (spec/rails_helper.rb).
    around(:example) { |ex| PaperTrailHelper.with_paper_trail { ex.run } }

    # No FactoryBot factory exists for UserGroupMember; build it directly (only
    # `:user_group` and `:user` factories exist).
    let(:user_group) { create(:user_group) }
    let(:user) { create(:user) }
    let(:member) { described_class.create!(user_group: user_group, user: user) }

    it 'describes a real create event from the group membership' do
      version = member.versions.last

      changes = described_class.describe_changes(version, {})

      expect(changes).to eq(["Added user \"#{user.name}\" to group"])
    end

    it 'falls back to raw object_changes YAML to identify the user when the item is destroyed' do
      member_id = member.id
      member.destroy

      version = PaperTrail::Version.where(item_type: 'UserGroupMember', item_id: member_id, event: 'destroy').last

      changes = described_class.describe_changes(version, {})

      expect(changes).to eq(["Removed user \"#{user.name}\" from group"])
    end
  end
end
