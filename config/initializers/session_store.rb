# Rails.logger.debug "Running initializer in #{__FILE__}"

# Be sure to restart your server when you modify this file.

# Use cookie-based sessions in test environment for reliability in system tests
# Cookie sessions store data encrypted in the browser cookie, avoiding Redis persistence issues
if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
  Rails.application.config.session_store(
    :cookie_store,
    key: "_#{Rails.application.class.module_parent_name.downcase}_session",
    httponly: true,
    same_site: :lax,
    secure: false,
  )
else
  Rails.application.config.session_store(
    :redis_store,
    servers: [
      {
        ssl: ENV.fetch('CACHE_SSL', false).to_s == 'true',
        host: ENV.fetch('CACHE_HOST', 'redis'),
        port: ENV.fetch('CACHE_PORT', 6379),
        db: ENV.fetch('CACHE_DB', 1),
      }
    ],
    expire_after: 12.hours, # If this expires while a session is open, the user is logged out
    key: "_#{Rails.application.class.module_parent_name.downcase}_session",
    httponly: true,
    same_site: :lax,
    secure: !Rails.env.test?, # CI fails when the session is secure
  )
end
