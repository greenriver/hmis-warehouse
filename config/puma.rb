# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

if ENV['PUMA_BIND']
  bind ENV['PUMA_BIND']
else
  # Specifies the `port` that Puma will listen on to receive requests; default is 3000.
  port (ENV["PROXY_PORT"] || ENV["PUMA_PORT"] || ENV['PORT'] || '3000').to_i
end

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

if ENV['PUMA_PIDFILE']
  pidfile ENV['PUMA_PIDFILE']
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
