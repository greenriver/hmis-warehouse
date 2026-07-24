# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe 'Restricted client visibility', type: :model do
  let!(:ds1) { create :hmis_primary_data_source }
  let!(:o1) { create :hmis_hud_organization, data_source: ds1 }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1 }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

  let!(:restricted_client_at_p1) do
    create(:hmis_hud_client, data_source: ds1, restricted: true, with_enrollment_at: p1)
  end

  let!(:unenrolled_restricted_client) do
    create(:hmis_hud_client, data_source: ds1, restricted: true)
  end

  let!(:user_view_only) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(hmis_user, p1, with_permission: [:can_view_clients])
    hmis_user
  end

  let!(:user_view_restricted) do
    hmis_user = create(:hmis_user, data_source: ds1)
    create_access_control(
      hmis_user,
      p1,
      with_permission: [:can_view_clients, :can_view_restricted_clients],
    )
    hmis_user
  end

  describe Hmis::Hud::Client do
    it 'hides restricted clients from users with only can_view_clients' do
      expect(Hmis::Hud::Client.viewable_by(user_view_only)).to be_empty
    end

    it 'shows restricted clients to users with can_view_restricted_clients at overlapping project' do
      expect(Hmis::Hud::Client.viewable_by(user_view_restricted)).to contain_exactly(restricted_client_at_p1)
    end

    it 'shows restricted client when user has both permissions at a different overlapping project' do
      create(:hmis_hud_enrollment, client: restricted_client_at_p1, project: p2)
      user = create(:hmis_user, data_source: ds1)
      create_access_control(
        user,
        p2,
        with_permission: [:can_view_clients, :can_view_restricted_clients],
      )

      expect(Hmis::Hud::Client.viewable_by(user)).to include(restricted_client_at_p1)
    end

    it 'hides unenrolled restricted clients from everyone' do
      expect(Hmis::Hud::Client.viewable_by(user_view_restricted)).not_to include(unenrolled_restricted_client)
    end
  end

  describe Hmis::AuthPolicies::HmisClientPolicy do
    it 'denies can_view? without can_view_restricted_clients for restricted clients' do
      policy = user_view_only.policy_for(restricted_client_at_p1, policy_type: :hmis_client)
      expect(policy.can_view?).to be false
    end

    it 'grants can_view? with both permissions for restricted clients' do
      policy = user_view_restricted.policy_for(restricted_client_at_p1, policy_type: :hmis_client)
      expect(policy.can_view?).to be true
      expect(policy.can_view_restricted_status?).to be true
    end
  end
end
