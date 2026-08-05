###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Role, type: :model do
  # These specs catch a bad config of Hmis::Role.permissions_with_descriptions
  describe '.permissions_with_descriptions config' do
    it 'requirements reference only permissions that exist' do
      requirements = described_class.permissions_with_descriptions.transform_values { |config| config[:requirements] || [] }
      expect(requirements.values.flatten.uniq - described_class.permissions).to be_empty
    end

    it 'declares no requirement cycles' do
      expect { described_class.permissions.each { |perm| described_class.required_permissions_for(perm) } }.not_to raise_error
    end

    it 'declares only direct requirements, not transitive ones' do
      redundant = described_class.permissions.filter_map do |permission|
        declared = described_class.permissions_with_descriptions[permission][:requirements] || []
        implied = declared.flat_map { |req| described_class.required_permissions_for(req) - [req] }
        overlap = declared & implied
        [permission, overlap] if overlap.any?
      end

      expect(redundant).to be_empty
    end
  end

  describe '.required_permissions_for' do
    it 'would report a cycle if one were introduced' do
      allow(described_class).to receive(:permissions_with_descriptions).and_return(
        can_view_project: { requirements: [:can_view_clients] },
        can_view_clients: { requirements: [:can_view_project] },
        can_administer_hmis: {},
      )

      expect { described_class.required_permissions_for(:can_view_project) }.to raise_error(/cycle detected/)
    end
  end
end
