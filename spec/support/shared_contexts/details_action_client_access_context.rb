# frozen_string_literal: true

# Shared context for testing that warehouse report `details` actions
# require client access via `require_can_access_some_version_of_clients!`.
#
# Including specs must define `details_path`.
RSpec.shared_context 'details action requires client access' do
  let(:user) { create(:user) }

  let(:report_role) do
    create(:role, can_view_assigned_reports: true)
  end

  let(:client_role) do
    create(:role, can_view_clients: true)
  end

  before do
    user.legacy_roles << report_role
    allow_any_instance_of(described_class).to receive(:report_visible?).and_return(true)
  end

  describe 'GET #details' do
    context 'when user lacks client access' do
      before { sign_in(user) }

      it 'denies access' do
        get details_path
        expect(response).to redirect_to(user.my_root_path)
      end
    end

    context 'when user has client access' do
      before do
        user.legacy_roles << client_role
        # Stub the action body to isolate auth from action-specific data requirements.
        expect_any_instance_of(described_class).to receive(:details) do |controller|
          controller.head :ok
        end
        sign_in(user)
      end

      it 'allows access' do
        get details_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
