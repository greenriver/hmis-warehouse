Rails.logger.debug "Running initializer in #{__FILE__}"

# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :two_factor_authenticatable
    manager.default_strategies(scope: :user).unshift :two_factor_backupable

    if ENV['DEVISE_JWT_SECRET_KEY'].present?
      Warden::JWTAuth.configure do |config|
        config.secret = ENV['DEVISE_JWT_SECRET_KEY']
        config.dispatch_requests = [
          ['POST', /^\/api\/login$/],
          ['POST', /^\/api\/login.json$/],
        ]
        config.revocation_requests = [
          ['DELETE', /^\/api\/logout$/],
          ['DELETE', /^\/api\/logout.json$/],
        ]
      end
    end
  end

  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # Devise will use the `secret_key_base` on Rails 4+ applications as its `secret_key`
  # by default. You can change it below and use your own secret key.
  # config.secret_key = '94fce868bb2c8cb73ca02fb7d349d869c718a5bb4b54638c7522f763edb8e8f0a4585117332673a4ef448bc85fa68a3763b59dc71d9f1f02cf5ad9cbba55adf1'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  # config.mailer_sender = 'noreply@example.com'

  # Configure the class responsible to send e-mails.
  config.mailer = 'AccountMailer'
  config.parent_mailer = 'ApplicationMailer'

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  # config.authentication_keys = [:email]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [:email]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [:email]

  # Tell if authentication through request.params is enabled. True by default.
  # It can be set to an array that will enable params authentication only for the
  # given strategies, for example, `config.params_authenticatable = [:database]` will
  # enable it only for database (email + password) authentication.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Auth is enabled. False by default.
  # It can be set to an array that will enable http authentication only for the
  # given strategies, for example, `config.http_authenticatable = [:database]` will
  # enable it only for database authentication. The supported strategies are:
  # :database      = Support basic authentication with authentication key + password
  # config.http_authenticatable = false

  # If 401 status code should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. 'Application' by default.
  # config.http_authentication_realm = 'Application'

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  # config.paranoid = true

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [:http_auth]

  # By default, Devise cleans up the CSRF token on authentication to
  # avoid CSRF token fixation attacks. This means that, when using AJAX
  # requests for sign in and sign up, you need to get a new CSRF token
  # from the server. You can disable this option at your own risk.
  config.clean_up_csrf_token_on_authentication = false
  # https://github.com/heartcombo/devise/blob/f8d1ea90bc328012f178b8a6616a89b73f2546a4/lib/devise/hooks/csrf_cleaner.rb#L6

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # encryptor), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  config.stretches = Rails.env.test? ? 1 : 10

  # Setup a pepper to generate the encrypted password.
  # config.pepper = 'c01c9bf55614c542c298cbfd963351a82b60fdfefa386f5f7b631bded013123add3857aedb1b806e089f6ed26db1bc893820d386d9d56cb68deea919e4e41f6a'

  # Send a notification email when the user's password is changed
  config.send_password_change_notification = true

  # ==> Configuration for :invitable
  # The period the generated invitation token is valid, after
  # this period, the invited resource won't be able to accept the invitation.
  # When invite_for is 0 (the default), the invitation won't expire.
  config.invite_for = 2.weeks

  # Number of invitations users can send.
  # - If invitation_limit is nil, there is no limit for invitations, users can
  # send unlimited invitations, invitation_limit column is not used.
  # - If invitation_limit is 0, users can't send invitations by default.
  # - If invitation_limit n > 0, users can send n invitations.
  # You can change invitation_limit column for some users so they can send more
  # or less invitations, even with global invitation_limit = 0
  # Default: nil
  # config.invitation_limit = 0

  # The key to be used to check existing users when sending an invitation
  # and the regexp used to test it when validate_on_invite is not set.
  config.invite_key = { email: nil }
  # config.invite_key = {:email => /\A[^@]+@[^@]+\z/, :username => nil}

  # Flag that force a record to be valid before being actually invited
  # Default: false
  config.validate_on_invite = true

  # Resend invitation if user with invited status is invited again
  # Default: true
  # config.resend_invitation = false

  # The class name of the inviting model. If this is nil,
  # the #invited_by association is declared to be polymorphic.
  # Default: nil
  # config.invited_by_class_name = 'User'

  # The foreign key to the inviting model (if invited_by_class_name is set)
  # Default: :invited_by_id
  # config.invited_by_foreign_key = :invited_by_id

  # The column name used for counter_cache column. If this is nil,
  # the #invited_by association is declared without counter_cache.
  # Default: nil
  # config.invited_by_counter_cache = :invitations_count

  # Auto-login after the user accepts the invite. If this is false,
  # the user will need to manually log in after accepting the invite.
  # Default: true
  # config.allow_insecure_sign_in_after_accept = false

  # ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day. Default is 0.days, meaning
  # the user cannot access the website without confirming their account.
  # config.allow_unconfirmed_access_for = 2.days

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 3.days, the user can confirm
  # their account within 3 days after the mail was sent, but on the fourth day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  config.confirm_within = 1.day

  # If true, requires any email changes to be confirmed (exactly the same way as
  # initial account confirmation) to be applied. Requires additional unconfirmed_email
  # db field (see migrations). Until confirmed, new email is stored in
  # unconfirmed_email column, and copied to email column on successful confirmation.
  config.reconfirmable = true

  # Defines which key will be used when confirming an account
  # config.confirmation_keys = [:email]

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  config.remember_for = 8.hours

  # Invalidates all the remember me tokens when the user signs out.
  config.expire_all_remember_me_on_sign_out = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  # config.rememberable_options = {}

  # ==> Configuration for :validatable
  # Range for password length.
  min_password_length = ENV.fetch('PASSWORD_MINIMUM_LENGTH') { 12 }.to_i
  config.password_length = min_password_length..128

  # Minimum number of times a pwned password must exist in the data set in order
  # to be reject.
  # config.min_password_matches = 2

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  # config.email_regexp = /\A[^@]+@[^@]+\z/

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  if Rails.env.development?
    config.timeout_in = ENV.fetch('LOGIN_TIMEOUT_MINUTES', 30).to_i.minutes
  else
    config.timeout_in = 30.minutes
  end

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  # config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  # config.unlock_keys = [:email]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  # config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  # FIXME: we need to double the number of attempts because of a bug in devise 2FA that
  # hasn't been fixed yet https://github.com/tinfoil/devise-two-factor/pull/136
  # https://github.com/tinfoil/devise-two-factor/pull/130
  config.maximum_attempts = ENV.fetch('PASSWORD_ATTEMPTS_ALLOWED') { 10 }.to_i * 2

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  unlock_in = ENV.fetch('ACCOUNT_UNLOCK_HOURS') { 1 }.to_i
  config.unlock_in = unlock_in.hour

  # Warn on the last attempt before the account is locked.
  config.last_attempt_warning = true

  # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  # config.reset_password_keys = [:email]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  reset_password_within = ENV.fetch('PASSWORD_RESET_VALID_FOR_MINUTES') { 360 }.to_i
  config.reset_password_within = reset_password_within.minutes

  # When set to false, does not sign a user in automatically after their password is
  # reset. Defaults to true, so a user is signed in automatically after a reset.
  config.sign_in_after_reset_password = false

  # ==> Configuration for :encryptable
  # Allow you to use another encryption algorithm besides bcrypt (default). You can use
  # :sha1, :sha512 or encryptors from others authentication tools as :clearance_sha1,
  # :authlogic_sha512 (then you should set stretches above to 20 for default behavior)
  # and :restful_authentication_sha1 (then you should set stretches to 10, and copy
  # REST_AUTH_SITE_KEY to pepper).
  #
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  # config.encryptor = :sha512

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = true

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # config.default_scope = :user

  # Set this configuration to false if you want /users/sign_out to sign out
  # only the current scope. By default, Devise signs out all scopes.
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The "*/*" below is required to match Internet Explorer requests.
  # config.navigational_formats = ['*/*', :html]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ==> Mountable engine configurations
  # When using Devise inside an engine, let's call it `MyEngine`, and this engine
  # is mountable, there are some extra configurations to be taken into account.
  # The following options are available, assuming the engine is mounted as:
  #
  #     mount MyEngine, at: '/my_engine'
  #
  # The router that invoked `devise_for`, in the example above, would be:
  # config.router_name = :my_engine
  #
  # When using OmniAuth, Devise cannot automatically set OmniAuth path,
  # so you need to do it manually. For the users scope, it would be:
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  # Allow 2FA to drift up to 90 seconds
  config.otp_allowed_drift = 90

  # ==> Security Extension
  # Configure security extension for devise

  # Should the password expire (e.g 3.months)
  # config.expire_password_after = false
  expire_password_after = ENV.fetch('PASSWORD_EXPIRATION_DAYS') { 'false' }
  if expire_password_after == 'true'
    config.expire_password_after = true
  elsif expire_password_after == 'false'
    config.expire_password_after = false
  else
    config.expire_password_after = expire_password_after.to_i
  end

  # Need 1 char of A-Z, a-z and 0-9
  if ENV.fetch('PASSWORD_COMPLEXITY_ENFORCED') { false } == 'true'
    config.password_complexity = { digit: 1, lower: 1, symbol: 1, upper: 1 }
  else
    config.password_complexity = {}
  end

  # How many passwords to keep in archive
  is_password_reuse_an_integer = ENV['PASSWORD_REUSE_LIMIT'].to_i.to_s == ENV['PASSWORD_REUSE_LIMIT']
  limit_password_reuse = is_password_reuse_an_integer || ENV['PASSWORD_REUSE_LIMIT'] == 'true'
  config.password_archiving_count = 50 if limit_password_reuse

  # Deny old passwords (true, false, number_of_old_passwords_to_check)
  # Examples:
  # config.deny_old_passwords = false # allow old passwords
  # config.deny_old_passwords = true # will deny all the old passwords
  # config.deny_old_passwords = 3 # will deny new passwords that matches with the last 3 passwords
  # config.deny_old_passwords = true
  if limit_password_reuse
    if is_password_reuse_an_integer
      config.deny_old_passwords = ENV['PASSWORD_REUSE_LIMIT'].to_i
    else
      config.deny_old_passwords = true
    end
  else
    config.deny_old_passwords = false
  end

  # enable email validation for :secure_validatable. (true, false, validation_options)
  # dependency: see https://github.com/devise-security/devise-security/blob/master/README.md#e-mail-validation
  # config.email_validation = true

  # captcha integration for recover form
  # config.captcha_for_recover = true

  # captcha integration for sign up form
  # config.captcha_for_sign_up = true

  # captcha integration for sign in form
  # config.captcha_for_sign_in = true

  # captcha integration for unlock form
  # config.captcha_for_unlock = true

  # captcha integration for confirmation form
  # config.captcha_for_confirmation = true

  # Time period for account expiry from last_activity_at
  expire_after = ENV.fetch('ACCOUNT_EXPIRATION_DAYS') { 180 }.to_i
  config.expire_after = expire_after.days

  if ENV['DEVISE_JWT_SECRET_KEY'].present?
    config.jwt do |jwt|
      jwt.secret = ENV['DEVISE_JWT_SECRET_KEY']
      jwt.dispatch_requests = [
        ['POST', /^\/api\/login$/],
        ['POST', /^\/api\/login.json$/],
      ]
      jwt.revocation_requests = [
        ['DELETE', /^\/api\/logout$/],
        ['DELETE', /^\/api\/logout.json$/],
      ]
      jwt.expiration_time = 1.day.to_i
      jwt.request_formats = { api_user: [:json] }
    end
  end

  if ENV['OKTA_DOMAIN'].present?
    require 'omni_auth/strategies/custom_okta'

    # Uncomment to allow sign in via OKTA with a simple GET request. See CVE-2015-9284
    # on reasons why you dont want that
    # OmniAuth.config.allowed_request_methods = [:post, :get]

    domain = ENV.fetch('OKTA_DOMAIN')
    auth_server = ENV.fetch('OKTA_AUTH_SERVER') { 'default' }

    # puts "OKTA: SSO enabled domain=#{domain}"

    connection_build_callback = if Rails.env.development?
      puts 'OKTA: WARNING: request logging enabled'

      ->(builder) do
        builder.request :url_encoded
        builder.response :logger, Rails.logger, { headers: true, bodies: true, log_level: :debug }
        builder.adapter Faraday.default_adapter
      end
    end

    config.omniauth(
      :okta,
      ENV.fetch('OKTA_CLIENT_ID'),
      ENV.fetch('OKTA_CLIENT_SECRET'),
      strategy_class: OmniAuth::Strategies::CustomOkta,
      scope: 'openid profile email phone',
      fields: ['profile', 'email', 'phone'],
      client_options: {
        site: "https://#{domain}",
        authorize_url: "https://#{domain}/oauth2/#{auth_server}/v1/authorize",
        token_url: "https://#{domain}/oauth2/#{auth_server}/v1/token",
        user_info_url: "https://#{domain}/oauth2/#{auth_server}/v1/userinfo",
        connection_build: connection_build_callback,
      },
    )
  end
end
