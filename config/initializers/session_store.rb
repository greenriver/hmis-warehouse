# Rails.logger.debug "Running initializer in #{__FILE__}"

# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_store,
  servers: ["redis://#{ENV.fetch('CACHE_HOST', 'redis')}:#{ENV.fetch('CACHE_PORT', 6379)}/#{ENV.fetch('CACHE_DB', 1)}/session"],
  expire_after: 12.hours, # If this expires while a session is open, the user is logged out
  key: "_#{Rails.application.class.module_parent_name.downcase}_session",
  secure: true
