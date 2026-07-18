###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Behavior of the AuthMethod (devise/JWT) branching that UserConcern mixes into both User and Hmis::User.
#
# The branch is resolved at *class-load*, so the suite is split by how CI boots:
#   - the default (Devise) suite asserts the DeviseUser concern, its macro, and the overrides that `super`
#     into the macro, and
#   - the JWT-boot suite (the dedicated AUTH_METHOD=jwt CI step) asserts the macro is absent and the Idp::JwtUser
#     branches are taken.
#
# Pass the factory + model class so the same expectations run against every UserConcern host.
RSpec.shared_examples 'an auth-method-aware user' do |factory, model|
  describe 'default (Devise) mode', if: AuthMethod.devise? do
    it 'includes the Devise auth concern and applies the macro and its injected accessors' do
      expect(model.include?(DeviseUser)).to be true
      expect(model.include?(Idp::JwtUser)).to be false
      expect(model.devise_modules).to be_present
      expect(model.devise_modules).to include(:two_factor_authenticatable)
      expect(model.new).to respond_to(:otp_secret)
    end

    describe 'two_factor_enabled?' do
      # Build the 2FA state inline (rather than via a devise-only factory) so it works for any host model.
      let(:user) do
        build(factory, otp_required_for_login: true, otp_secret: model.generate_otp_secret, confirmed_2fa: 2)
      end

      it 'exercises the real otp_secret/otp_required_for_login? path' do
        expect(user.two_factor_enabled?).to be true
      end

      it 'is false unless otp_secret, otp_required_for_login, and a passed 2fa confirmation all hold' do
        # two_factor_enabled? ANDs three predicates. The case above only proves the all-true result; flipping
        # each predicate in turn pins the AND, so dropping any one conjunct (treating a half-configured account
        # as 2FA-protected) turns this red.
        enabled = { otp_required_for_login: true, otp_secret: model.generate_otp_secret, confirmed_2fa: 2 }

        expect(build(factory, **enabled, otp_secret: nil).two_factor_enabled?).to be false
        expect(build(factory, **enabled, otp_required_for_login: false).two_factor_enabled?).to be false
        expect(build(factory, **enabled, confirmed_2fa: 0).two_factor_enabled?).to be false
      end

      # The JWT branch (two_factor_enabled? => false) is now selected at load time, so it is not observable
      # via a runtime ENV flip in a Devise process; it is asserted in the JWT-boot suite below instead.
    end

    # These overrides `super` into the Devise macro, so they are defined inside DeviseUser's `included do`
    # (i.e. on the host class, below the macro modules) rather than as plain module methods, which the macro
    # would shadow. Each assertion below distinguishes the override from bare Devise behavior, so it fails if
    # the override is ever silently shadowed again.
    describe 'Devise overrides resolve above the macro' do
      it 'active_for_authentication? ANDs the `active` flag on top of Devise' do
        # Bare Devise returns true for a confirmed, unlocked user; the override additionally gates on `active`.
        expect(build(factory, active: true).active_for_authentication?).to be true
        expect(build(factory, active: false).active_for_authentication?).to be false
      end

      it 'active_for_authentication? still consults Devise (super), not the `active` flag alone' do
        # The override is `super && active`. The case above only exercises the `&& active` half: an
        # active-and-otherwise-valid user. This pins the `super` half — a locked-out account must fail
        # authentication even though `active` is true — so collapsing the override to a bare `active`
        # check (dropping Devise's confirmation/lockout/expiry gate, an auth bypass) turns this red.
        locked = build(factory, active: true, locked_at: Time.current)

        expect(locked.access_locked?).to be true # sanity: the Devise lockout gate is what should win
        expect(locked.active_for_authentication?).to be false
      end

      it 'authenticatable_salt poisons the salt with custom_session_invalidator' do
        user = create(factory)
        base = user.authenticatable_salt
        user.custom_session_invalidator = SecureRandom.hex
        poisoned = user.authenticatable_salt

        # Bare Devise ignores custom_session_invalidator entirely and would return `base` unchanged.
        expect(poisoned).not_to eq(base)
        expect(poisoned.length).to eq(base.length)
      end

      it 'find_for_authentication looks users up case-insensitively' do
        user = create(factory, email: 'mixed.case@greenriver.com')
        # The override downcases conditions[:email] in place; real callers pass mutable request params, so
        # dup the frozen string literal here.
        expect(model.find_for_authentication(email: 'MIXED.CASE@GREENRIVER.COM'.dup)).to eq(user)
      end

      it 'send_reset_password_instructions refuses while an invitation is open' do
        user = build(factory)
        user.invitation_token = 'open-token'

        expect(user.send_reset_password_instructions).to be false
        expect(user.errors[:email]).to include('There is an open invitation for this account.')
      end

      it 'send_reset_password_instructions falls through to Devise when no invitation is open' do
        # The `else super` branch: this proves the override reaches Devise :recoverable rather than just
        # short-circuiting. Devise persists a reset_password_token before notifying, so a changed token is
        # observable evidence that super ran. Stub only the delivery — Hmis::User has no warehouse
        # password-reset mailer route — so the assertion stays host-agnostic and tests the logic, not mail.
        user = create(factory)
        allow(user).to receive(:send_devise_notification)

        expect { user.send_reset_password_instructions }.to change { user.reload.reset_password_token }.from(nil)
      end

      it 'pending_any_confirmation refuses while an invitation is open' do
        user = build(factory)
        user.invitation_token = 'open-token'

        expect(user.pending_any_confirmation).to be false
        expect(user.errors[:email]).to include('There is an open invitation for this account.')
      end
    end

    # These helpers were moved verbatim out of UserConcern into DeviseUser. They don't `super` into the
    # macro, but most read or write columns/accessors the macro injects (otp_*, custom_session_invalidator,
    # the trackable/expirable activity columns). Exercising them — rather than just asserting they're
    # `defined?` — proves the move kept them wired to the macro-backed model rather than silently dropping
    # one or detaching it from the Devise machinery.
    describe 'moved Devise helpers run against the macro' do
      it 'two_factor_label / two_factor_issuer build from the model and email' do
        user = build(factory, email: 'tester@greenriver.com')
        expect(user.two_factor_label).to be_present
        expect(user.two_factor_issuer).to include('tester@greenriver.com')
      end

      it 'confirmation_step / passed_2fa_confirmation? read confirmed_2fa' do
        expect(build(factory, confirmed_2fa: 1).confirmation_step).to eq('2nd')
        expect(build(factory, confirmed_2fa: 0).passed_2fa_confirmation?).to be false
        expect(build(factory, confirmed_2fa: 2).passed_2fa_confirmation?).to be true
      end

      it 'reset_two_factor_model_attrs clears the macro-injected otp accessors' do
        user = build(factory, otp_required_for_login: true, otp_secret: model.generate_otp_secret, confirmed_2fa: 2)

        user.reset_two_factor_model_attrs

        expect(user.otp_secret).to be_nil
        expect(user.confirmed_2fa).to eq(0)
        expect(user.otp_required_for_login).to be false
      end

      it 'set_initial_two_factor_secret! generates a secret only when one is absent' do
        user = create(factory, otp_secret: nil)

        expect { user.set_initial_two_factor_secret! }.to change { user.reload.otp_secret }.from(nil)
        existing = user.otp_secret
        # Idempotent: a second call is a no-op when a secret already exists.
        expect { user.set_initial_two_factor_secret! }.not_to(change { user.reload.otp_secret })
        expect(user.otp_secret).to eq(existing)
      end

      it 'disable_2fa! persists the cleared 2FA state' do
        user = create(factory, otp_required_for_login: true, confirmed_2fa: 2)

        user.disable_2fa!

        expect(user.reload.otp_required_for_login).to be false
        expect(user.confirmed_2fa).to eq(0)
      end

      it 'force_logout! rotates the custom_session_invalidator' do
        user = create(factory)

        expect { user.force_logout! }.to(change { user.reload.custom_session_invalidator })
      end

      it 'record_failure_and_lock_access_if_exceeded! double-increments failed attempts via the lockable macro' do
        user = create(factory)

        # The method intentionally increments twice per call to compensate for a Devise double-counting
        # bug (see the comment in DeviseUser). Asserting +2 against the macro-backed failed_attempts column
        # pins that workaround so a regression to a single increment (which would halve the real lockout
        # threshold) turns this red.
        expect { user.record_failure_and_lock_access_if_exceeded! }.
          to change { user.reload.failed_attempts }.by(2)
      end

      it 'record_failure_and_lock_access_if_exceeded! locks the account once the doubled count crosses the threshold' do
        user = create(factory)
        # Stub only the unlock-instructions delivery so the assertion stays host-agnostic (Hmis::User has no
        # warehouse unlock mailer route); the locked_at write still persists through lock_access!.
        allow(user).to receive(:send_devise_notification)
        # Seed one below the threshold so a single (doubled) call crosses maximum_attempts and trips the lock.
        user.update_column(:failed_attempts, model.maximum_attempts - 1)

        expect { user.record_failure_and_lock_access_if_exceeded! }.
          to change { user.reload.access_locked? }.from(false).to(true)
      end

      it 'skip_session_limitable? defaults to false when the env var is unset' do
        expect(build(factory).skip_session_limitable?).to be false
      end

      it 'overall_status reports Active via active_for_authentication? (super into Devise)' do
        expect(create(factory, active: true).overall_status(nil)).to eq(['Active'])
      end

      it 'overall_status surfaces the deactivated state via the private deactivation_status' do
        user = create(factory, active: false)

        expect(user.overall_status(user)).to include('Account deactivated')
      end

      it 'active / inactive scopes partition on the `active` flag' do
        active_user = create(factory, active: true)
        inactive_user = create(factory, active: false)

        expect(model.active).to include(active_user)
        expect(model.active).not_to include(inactive_user)
        expect(model.inactive).to include(inactive_user)
        expect(model.inactive).not_to include(active_user)
      end

      it 'active / inactive scopes treat an expired (but active-flagged) account as inactive' do
        # active: true isolates the expired_at clause as the only thing that can move this row, so dropping
        # that clause from the scopes (an expired account silently counting as active) turns this red.
        expired = create(factory, active: true, expired_at: 1.day.ago)

        expect(model.active).not_to include(expired)
        expect(model.inactive).to include(expired)
      end

      it 'active / inactive scopes treat an account idle past expire_after as inactive' do
        # Likewise isolates the last_activity_at/expire_after clause: only staleness can move an active,
        # unexpired row, so dropping that clause turns this red.
        idle = create(factory, active: true, last_activity_at: model.expire_after.ago - 1.day)

        expect(model.active).not_to include(idle)
        expect(model.inactive).to include(idle)
      end

      it 'has_recent_activity counts a current session in either the warehouse or HMIS, not both' do
        warehouse_only = create(factory, last_activity_at: Time.current, unique_session_id: SecureRandom.hex)
        hmis_only = create(factory, last_activity_at: Time.current, hmis_unique_session_id: SecureRandom.hex)
        no_session = create(factory, last_activity_at: Time.current)

        # `where.not(unique_session_id: nil, hmis_unique_session_id: nil)` negates an AND, so it matches when
        # EITHER id is present. Building single-session users pins the OR: tightening it to require both
        # (an easy mis-edit) would drop warehouse_only/hmis_only and turn this red, while no_session proves
        # the clause still excludes the session-less row.
        expect(model.has_recent_activity).to include(warehouse_only, hmis_only)
        expect(model.has_recent_activity).not_to include(no_session)
      end

      it 'has_recent_activity excludes a session whose last activity is outside the timeout window' do
        sessions = { unique_session_id: SecureRandom.hex, hmis_unique_session_id: SecureRandom.hex }
        fresh = create(factory, last_activity_at: Time.current, **sessions)
        stale = create(factory, last_activity_at: model.timeout_in.ago - 1.hour, **sessions.transform_values { SecureRandom.hex })

        # Both have sessions, so only the last_activity_at window separates them; dropping that clause lets
        # the stale session count as recent.
        expect(model.has_recent_activity).to include(fresh)
        expect(model.has_recent_activity).not_to include(stale)
      end
    end

    # PasswordRules moved out of an unconditional UserConcern `included do` into the Devise-only branch, and
    # its `validate :password_cannot_be_sequential, on: :update` macro moved with it into PasswordRules' own
    # `included do`. Because PasswordRules is now mixed into the host through a *conditional branch* of one
    # concern rather than an `included do`, its macro only reaches the model via ActiveSupport::Concern's
    # dependency replay. Exercising the validation and the public helper — rather than asserting `include?`
    # alone — proves the replay still lands the callback and the instance methods on the macro-backed model.
    describe 'confirm_password_for_admin_actions?' do
      it 'follows OmniauthSupport (!external_idp?): local-password users re-confirm, external-IdP users do not' do
        user = build(factory)
        allow(user).to receive(:external_idp?).and_return(false)
        expect(user.confirm_password_for_admin_actions?).to be true

        allow(user).to receive(:external_idp?).and_return(true)
        expect(user.confirm_password_for_admin_actions?).to be false
      end
    end

    describe 'profile_managed_by_idp?' do
      it 'follows external_idp?: Okta-linked users are IdP-managed (read-only), local accounts are not' do
        user = build(factory)
        allow(user).to receive(:external_idp?).and_return(false)
        expect(user.profile_managed_by_idp?).to be false

        allow(user).to receive(:external_idp?).and_return(true)
        expect(user.profile_managed_by_idp?).to be true
      end
    end

    describe 'email_change_enabled?' do
      it 'is the inverse of profile_managed_by_idp?: local accounts may change email, IdP-managed ones may not' do
        user = build(factory)
        allow(user).to receive(:external_idp?).and_return(false)
        expect(user.email_change_enabled?).to be true
        expect(user.email_change_enabled?).to eq(!user.profile_managed_by_idp?)

        allow(user).to receive(:external_idp?).and_return(true)
        expect(user.email_change_enabled?).to be false
        expect(user.email_change_enabled?).to eq(!user.profile_managed_by_idp?)
      end
    end

    describe 'account_expiry_enabled?' do
      it 'is true regardless of external_idp? (Devise enforces expired_at for local and Okta accounts)' do
        user = build(factory)
        allow(user).to receive(:external_idp?).and_return(false)
        expect(user.account_expiry_enabled?).to be true

        allow(user).to receive(:external_idp?).and_return(true)
        expect(user.account_expiry_enabled?).to be true
      end
    end

    describe 'PasswordRules applies under Devise' do
      it 'mixes PasswordRules into the host' do
        expect(model.include?(PasswordRules)).to be true
      end

      it 'exposes password_rules guidance built from the Devise config' do
        # password_rules is rendered by the password/invitation views, so it must resolve against the host.
        rules = build(factory).password_rules
        expect(rules).to be_an(Array)
        expect(rules).to include(a_string_matching(/at least .* characters/))
      end

      it 'rejects a sequential password on update when sequential enforcement is on' do
        user = create(factory)
        # Enforcement is env-driven (PASSWORD_SEQUENTIAL_CHARACTERS_ENFORCED); stub the predicate so the test
        # pins the validation logic, not the deployment's env. Setting `password` marks encrypted_password
        # dirty, which is what `changing_password?` keys off of, so the :update-context validate fires.
        allow(user).to receive(:password_sequential_characters_enforced?).and_return(true)
        user.password = user.password_confirmation = 'Abcd1234!'

        expect(user.valid?(:update)).to be false
        expect(user.errors[:password]).to include('has a sequential set of characters or digits')
      end

      it 'allows a non-sequential password on update (isolates the sequential check)' do
        user = create(factory)
        allow(user).to receive(:password_sequential_characters_enforced?).and_return(true)
        user.password = user.password_confirmation = 'Tr0ub4d:Kx7w'

        user.valid?(:update)
        # Other rules may add their own :password errors; assert only that the sequential check — the behavior
        # that moved — does not fire for a non-sequential value, so this stays decoupled from the rest.
        expect(user.errors[:password]).not_to include('has a sequential set of characters or digits')
      end
    end
  end

  # These assertions require the class to have *loaded* under AUTH_METHOD=jwt
  describe 'JWT-boot (AUTH_METHOD=jwt process)', if: AuthMethod.jwt? do
    it 'omits the Devise auth concern, the macro, and its injected accessors' do
      expect(model.include?(DeviseUser)).to be false
      expect(model.include?(Idp::JwtUser)).to be true
      expect(model.respond_to?(:devise_modules)).to be false
      # `otp_secret` is a plain DB column since the devise-two-factor upgrade (migration
      # 20260715120000_add_otp_secret_to_users), so ActiveRecord defines the accessor on
      # every user regardless of arm — it no longer discriminates. Assert instead on a
      # method the :two_factor_authenticatable macro injects (absent under JWT).
      expect(model.new.respond_to?(:validate_and_consume_otp!)).to be false
    end

    describe 'two_factor_enabled?' do
      it 'returns false without raising (the macro accessors are absent)' do
        expect { model.new.two_factor_enabled? }.not_to raise_error
        expect(model.new.two_factor_enabled?).to be false
      end
    end

    describe 'gated scopes' do
      it 'build a query without referencing absent macro members (expire_after / timeout_in)' do
        expect { model.active.to_sql }.not_to raise_error
        expect { model.inactive.to_sql }.not_to raise_error
        expect { model.has_recent_activity.to_sql }.not_to raise_error
      end

      it 'has_recent_activity reports no sessions (warehouse sessions do not exist under JWT)' do
        expect(model.has_recent_activity).to eq(model.none)
      end
    end

    describe 'gated methods' do
      it 'reports no invitation status under JWT (invitations are IdP-managed)' do
        # Under JWT the IdP owns the account lifecycle, so the in-app invitation concept does not apply.
        # invitation_status short-circuits to nil rather than reading the :invitable members the gated-off
        # macro would manage (the invitation_sent_at column and the computed invitation_due_at method).
        user = model.new(invitation_sent_at: 1.hour.ago)
        expect { user.invitation_status }.not_to raise_error
        expect(user.invitation_status).to be_nil
      end

      it 'always reports not-stale under JWT, even for an account stale by the Devise trackable column' do
        # The IdP owns inactivity under JWT; stale_account? must short-circuit to false rather than read
        # current_sign_in_at (a :trackable column). A nil column would raise on the Devise comparison, and a
        # year-old timestamp would be stale under Devise — both return false here, proving the guard wins.
        expect(model.new(current_sign_in_at: nil).stale_account?).to be false
        expect(model.new(current_sign_in_at: 1.year.ago).stale_account?).to be false
      end

      it 'does not define find_for_authentication (Devise login must never run under JWT)' do
        # The override lives in DeviseUser, which is not included under JWT, and nothing else defines it.
        # Calling it would raise NoMethodError; assert on the absence directly rather than on the error string.
        expect(model.respond_to?(:find_for_authentication)).to be false
      end
    end

    describe 'confirm_password_for_admin_actions?' do
      it 'is always false (credentials are IdP-managed; the admin surface never renders the field)' do
        # Idp::Support defines the predicate as a flat false so any both-mode-reachable caller
        # resolves it, and the JWT admin surface never prompts for a local password.
        expect(model.new.confirm_password_for_admin_actions?).to be false
      end
    end

    describe 'profile_managed_by_idp?' do
      it 'is true (name/email are provisioned from the JWT; the admin form renders them read-only)' do
        expect(model.new.profile_managed_by_idp?).to be true
      end
    end

    describe 'email_change_enabled?' do
      it 'is false, the inverse of profile_managed_by_idp? (the IdP owns email; self-service change is blocked)' do
        # A local email edit would not reach the IdP and would be overwritten from the JWT on next login.
        user = model.new
        expect(user.email_change_enabled?).to be false
        expect(user.email_change_enabled?).to eq(!user.profile_managed_by_idp?)
      end
    end

    describe 'account_expiry_enabled?' do
      it 'is false (the IdP does not honor local expired_at; the admin form hides the field)' do
        expect(model.new.account_expiry_enabled?).to be false
      end
    end

    describe 'PasswordRules' do
      it 'is not mixed in (password management is IdP-owned under JWT)' do
        # PasswordRules now lives only in the Devise branch of UserConcern, so neither the concern nor its
        # public helper is present under JWT. The password/invitation views that call password_rules are
        # behind the AuthMethod.devise? route guard, so the helper has no caller here.
        expect(model.include?(PasswordRules)).to be false
        expect(model.new.respond_to?(:password_rules)).to be false
      end
    end

    describe 'setup_system_user' do
      it 'creates the system user without the macro-only invite! helper' do
        model.with_deleted.where(email: 'noreply@greenriver.com').delete_all

        user = nil
        expect { user = model.setup_system_user }.not_to raise_error
        expect(user).to be_persisted
        expect(user.email).to eq('noreply@greenriver.com')
        # idempotent: a second call returns the same record rather than re-inviting
        expect(model.setup_system_user.id).to eq(user.id)
      end
    end
  end
end
