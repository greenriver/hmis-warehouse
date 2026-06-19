###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Proves the AuthMethod conditions in UserConcern for the devise/JWT transition
#
# The devise macro gate runs at *class-load*, so an in-example ENV flip cannot re-evaluate it on an already-loaded
# User. The spec is therefore split across the two ways CI boots, each block guarded so it is a no-op in the
# other boot:
#   - default (Devise) suite (`if: AuthMethod.devise?`): the macro is applied, plus the one call-time guard
#     (two_factor_enabled?) that stays observable even with the macro present, and
#   - JWT-boot suite (`if: AuthMethod.jwt?`, the dedicated CI step): the macro is absent, the plain helper
#     defs survive the gate (RETAINED_HELPERS), and the gated scopes/methods take their JWT branches.
RSpec.describe 'UserConcern auth-method macro gate', type: :model do
  # Regression guard data: these helpers are defined directly in UserConcern and call `super` into the
  # Devise macro chain, so gating the macro must not drop their *definitions* (i.e. they must not be moved
  # inside the `if AuthMethod.devise?` block).
  RETAINED_HELPERS = [
    :authenticatable_salt,
    :send_reset_password_instructions,
    :pending_any_confirmation,
  ].freeze

  describe 'default (Devise) mode', if: AuthMethod.devise? do
    it 'applies the devise macro and its injected accessors' do
      expect(User.devise_modules).to be_present
      expect(User.devise_modules).to include(:two_factor_authenticatable)
      expect(User.new).to respond_to(:otp_secret)
    end

    describe 'two_factor_enabled?' do
      let(:user) { build(:user_2fa) }

      it 'exercises the real otp_secret/otp_required_for_login? path' do
        expect(user.two_factor_enabled?).to be true
      end

      it 'short-circuits to false (and does not raise) when AuthMethod is jwt' do
        # The Task 2 guard is evaluated at call-time, so it is observable on the already-loaded User even
        # though the macro itself stays applied in this process. Using a :user_2fa proves the guard wins
        # over an otherwise-true body.
        allow(AuthMethod).to receive(:devise?).and_return(false)
        allow(AuthMethod).to receive(:jwt?).and_return(true)

        expect(user.two_factor_enabled?).to be false
      end
    end
  end

  # These assertions require the class to have *loaded* under AUTH_METHOD=jwt
  describe 'JWT-boot (AUTH_METHOD=jwt process)', if: AuthMethod.jwt? do
    it 'omits the devise macro and its injected accessors' do
      expect(User.respond_to?(:devise_modules)).to be false
      expect(User.new.respond_to?(:otp_secret)).to be false
    end

    it 'retains the helper definitions (they are not gated out with the macro)' do
      # Retention-of-definition only: these are plain defs in UserConcern, so the macro gate must not drop
      # them.
      RETAINED_HELPERS.each do |helper|
        expect(User.method_defined?(helper)).to be(true), "expected User to still define ##{helper}"
      end
    end

    describe 'two_factor_enabled?' do
      it 'returns false without raising (the macro accessors are absent)' do
        expect { User.new.two_factor_enabled? }.not_to raise_error
        expect(User.new.two_factor_enabled?).to be false
      end
    end

    describe 'Task 3 gated scopes' do
      it 'build a query without referencing absent macro members (expire_after / timeout_in)' do
        expect { User.active.to_sql }.not_to raise_error
        expect { User.inactive.to_sql }.not_to raise_error
        expect { User.has_recent_activity.to_sql }.not_to raise_error
      end

      it 'has_recent_activity reports no sessions (warehouse sessions do not exist under JWT)' do
        expect(User.has_recent_activity).to eq(User.none)
      end
    end

    describe 'Task 3 gated methods' do
      it 'evaluates active_for_authentication? off active? without super into the absent macro chain' do
        expect { User.new.active_for_authentication? }.not_to raise_error
        expect(User.new(active: true).active_for_authentication?).to be true
        expect(User.new(active: false).active_for_authentication?).to be false
      end

      it 'reports no invitation status under JWT (invitations are IdP-managed)' do
        # Under JWT the IdP owns the account lifecycle, so the in-app invitation concept does not apply.
        # invitation_status short-circuits to nil rather than reading the :invitable members the gated-off
        # macro would manage (the invitation_sent_at column and the computed invitation_due_at method).
        user = User.new(invitation_sent_at: 1.hour.ago)
        expect { user.invitation_status }.not_to raise_error
        expect(user.invitation_status).to be_nil
      end

      it 'always reports not-stale under JWT, even for an account stale by the Devise trackable column' do
        # The IdP owns inactivity under JWT; stale_account? must short-circuit to false rather than read
        # current_sign_in_at (a :trackable column). A nil column would raise on the Devise comparison, and a
        # year-old timestamp would be stale under Devise — both return false here, proving the guard wins.
        expect(User.new(current_sign_in_at: nil).stale_account?).to be false
        expect(User.new(current_sign_in_at: 1.year.ago).stale_account?).to be false
      end

      it 'raises in find_for_authentication (Devise login must never run under JWT)' do
        expect { User.find_for_authentication(email: 'someone@example.test') }.to raise_error(/Devise login should never run/)
      end

      describe 'timeout_time' do
        it 'always returns nil under JWT (IdP-managed sessions are not knowable here)' do
          # No warehouse-side timeout exists under JWT, and the method must not reach into the absent
          # Devise :timeoutable math regardless of what the caller passes.
          expect(User.new.timeout_time(nil)).to be_nil
          expect(User.new.timeout_time('')).to be_nil
          expect(User.new.timeout_time('a.b.c')).to be_nil
          expect(User.new.timeout_time('last_request_at' => Time.current)).to be_nil
        end
      end
    end

    describe 'setup_system_user' do
      it 'creates the system user without the macro-only invite! helper' do
        User.with_deleted.where(email: 'noreply@greenriver.com').delete_all

        user = nil
        expect { user = User.setup_system_user }.not_to raise_error
        expect(user).to be_persisted
        expect(user.email).to eq('noreply@greenriver.com')
        # idempotent: a second call returns the same record rather than re-inviting
        expect(User.setup_system_user.id).to eq(user.id)
      end
    end
  end
end
