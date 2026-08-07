###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::RestrictedClientEnrollment, type: :model do
  let!(:ds1) { create :hmis_primary_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let!(:restricted_client_at_p1) { create(:hmis_hud_client, data_source: ds1, restricted: true, with_enrollment_at: p1) }
  let!(:unenrolled_restricted_client) { create(:hmis_hud_client, data_source: ds1, restricted: true) }
  let!(:unrestricted_client_at_p1) { create(:hmis_hud_client, data_source: ds1, with_enrollment_at: p1) }

  let(:user_view_restricted_at_p1) do
    user = create(:hmis_user, data_source: ds1)
    create_access_control(user, p1, with_permission: [:can_view_clients, :can_view_restricted_clients])
    user
  end

  let(:user_view_restricted_at_p2) do
    user = create(:hmis_user, data_source: ds1)
    create_access_control(user, p2, with_permission: [:can_view_clients, :can_view_restricted_clients])
    user
  end

  let(:user_view_only) do
    user = create(:hmis_user, data_source: ds1)
    create_access_control(user, p1, with_permission: [:can_view_clients])
    user
  end

  describe 'the view contents' do
    it 'includes one row per enrollment for a restricted client' do
      enrollment = restricted_client_at_p1.enrollments.first
      rows = described_class.where(client_id: restricted_client_at_p1.id)

      expect(rows.pluck(:enrollment_id, :project_id)).to contain_exactly([enrollment.id, p1.id])
    end

    it 'includes a placeholder row with no enrollment for an unenrolled restricted client' do
      rows = described_class.where(client_id: unenrolled_restricted_client.id)

      expect(rows.pluck(:enrollment_id, :project_id)).to contain_exactly([nil, nil])
    end

    it 'excludes clients that are not restricted' do
      expect(described_class.where(client_id: unrestricted_client_at_p1.id)).to be_empty
    end

    it 'excludes clients whose restriction has been removed' do
      Hmis::RestrictedRecord.unmark!(restricted_client_at_p1)

      expect(described_class.where(client_id: restricted_client_at_p1.id)).to be_empty
    end

    it 'excludes deleted clients, whose restriction is destroyed along with them' do
      restricted_client_at_p1.destroy!

      expect(Hmis::RestrictedRecord.where(restrictable: restricted_client_at_p1)).to be_empty
      expect(described_class.where(client_id: restricted_client_at_p1.id)).to be_empty
    end

    it 'includes an additional row when the client is enrolled at a second project' do
      create(:hmis_hud_enrollment, client: restricted_client_at_p1, data_source: ds1, project: p2)

      rows = described_class.where(client_id: restricted_client_at_p1.id)
      expect(rows.pluck(:project_id)).to contain_exactly(p1.id, p2.id)
    end

    it 'excludes deleted enrollments' do
      restricted_client_at_p1.enrollments.first.destroy!

      rows = described_class.where(client_id: restricted_client_at_p1.id)
      expect(rows.pluck(:enrollment_id, :project_id)).to contain_exactly([nil, nil])
    end
  end

  # These return relations rather than arrays so callers can pass them straight to
  # `where.not(id: ...)` as a subquery, hence the plucks below.
  describe '.client_ids_hidden_from' do
    it 'hides a restricted client from a user without can_view_restricted_clients' do
      expect(described_class.client_ids_hidden_from(user_view_only).pluck(:client_id)).to include(restricted_client_at_p1.id)
    end

    it 'does not hide a restricted client from a user with the permission at an enrolled project' do
      expect(described_class.client_ids_hidden_from(user_view_restricted_at_p1).pluck(:client_id)).not_to include(restricted_client_at_p1.id)
    end

    it 'hides a restricted client when the permission is at a project the client is not enrolled at' do
      expect(described_class.client_ids_hidden_from(user_view_restricted_at_p2).pluck(:client_id)).to include(restricted_client_at_p1.id)
    end

    it 'hides unenrolled restricted clients from everyone' do
      expect(described_class.client_ids_hidden_from(user_view_restricted_at_p1).pluck(:client_id)).to include(unenrolled_restricted_client.id)
    end
  end

  describe '.enrollment_ids_hidden_from' do
    it 'returns the enrollments of hidden clients' do
      enrollment = restricted_client_at_p1.enrollments.first

      expect(described_class.enrollment_ids_hidden_from(user_view_only).pluck(:enrollment_id)).to contain_exactly(enrollment.id)
    end

    it 'is empty when the user can unlock the client' do
      expect(described_class.enrollment_ids_hidden_from(user_view_restricted_at_p1)).to be_empty
    end

    # The placeholder rows carry a NULL enrollment_id. Callers feed this into `where.not(id: ...)`,
    # which builds a NOT IN, and a single NULL there would match zero rows.
    it 'never includes a nil, even when an unenrolled restricted client is hidden' do
      expect(described_class.client_ids_hidden_from(user_view_restricted_at_p1).pluck(:client_id)).to include(unenrolled_restricted_client.id)
      expect(described_class.enrollment_ids_hidden_from(user_view_restricted_at_p1).pluck(:enrollment_id)).not_to include(nil)
    end
  end
end
