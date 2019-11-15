set :deploy_to, "/var/www/#{fetch(:client)}-hmis-staging"
set :rails_env, 'staging'
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Delayed Job
set :delayed_job_pools, { low_priority: 2, default_priority: 1, high_priority: 1, nil => 1}

web_hosts = ENV['STAGING_HOSTS_WEB'].to_s.split(/,/)
utility_hosts = ENV['STAGING_HOSTS_UTILITY'].to_s.split(/,/)
cron_host = ENV['STAGING_HOST_WITH_CRON']

hosts = (web_hosts + utility_hosts + [cron_host]).uniq.sort

puts "Hosts specified for deployment: #{hosts}"

hosts.each do |host|
  roles = ['app']

  roles << 'web' if web_hosts.include?(host)
  roles << 'job' if utility_hosts.include?(host)
  roles << 'db' if cron_host == host
  roles << 'cron' if cron_host == host

  server host, user: ENV['DEPLOY_USER'], roles: roles, port: fetch(:ssh_port)
end
