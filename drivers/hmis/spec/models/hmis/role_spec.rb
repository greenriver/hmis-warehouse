###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Role, type: :model do
  describe '.required_permissions_for' do
    it 'returns just the permission when it has no requirements' do
      expect(described_class.required_permissions_for(:can_view_project)).to eq([:can_view_project])
    end

    it 'includes direct requirements' do
      expect(described_class.required_permissions_for(:can_view_enrollment_details)).
        to contain_exactly(:can_view_enrollment_details, :can_view_project, :can_view_clients)
    end

    it 'includes requirements of requirements' do
      # can_delete_enrollments -> can_edit_enrollments -> can_view_enrollment_details -> project, clients
      expect(described_class.required_permissions_for(:can_delete_enrollments)).
        to contain_exactly(
          :can_delete_enrollments,
          :can_edit_enrollments,
          :can_view_enrollment_details,
          :can_view_project,
          :can_view_clients,
        )
    end

    it 'returns each permission once' do
      permissions = described_class.required_permissions_for(:can_enroll_clients)
      expect(permissions).to eq(permissions.uniq)
    end

    it 'raises on an unknown permission' do
      expect { described_class.required_permissions_for(:can_do_something_nonexistent) }.
        to raise_error(/unknown permission/)
    end
  end
end
