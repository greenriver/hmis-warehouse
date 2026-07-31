###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Role, type: :model do
  # Requirements are resolved recursively when a user's permissions are evaluated
  # (Hmis::AuthPolicies::ContextLoaders::HmisPermissionLoader), which raises on a cycle.
  # These specs catch a bad config here rather than on every request that checks permissions.
  describe 'permission requirements' do
    let(:requirements) do
      described_class.permissions_with_descriptions.transform_values { |config| config[:requirements] || [] }
    end

    # Permissions reachable by following requirements from the given permission.
    # Includes the permission itself only when it participates in a cycle.
    def reachable_requirements(permission)
      reachable = Set.new
      unresolved = requirements.fetch(permission).dup

      while (perm = unresolved.shift)
        next unless reachable.add?(perm)

        unresolved.concat(requirements.fetch(perm, []))
      end

      reachable
    end

    def cyclic_permissions
      requirements.keys.select { |permission| reachable_requirements(permission).include?(permission) }
    end

    it 'reference only permissions that exist' do
      expect(requirements.values.flatten.uniq - described_class.permissions).to be_empty
    end

    it 'contain no cycles' do
      expect(cyclic_permissions).to be_empty
    end

    it 'would report a cycle if one were introduced' do
      allow(described_class).to receive(:permissions_with_descriptions).and_return(
        can_view_project: { requirements: [:can_view_clients] },
        can_view_clients: { requirements: [:can_view_project] },
        can_administer_hmis: {},
      )

      expect(cyclic_permissions).to contain_exactly(:can_view_project, :can_view_clients)
    end
  end
end
