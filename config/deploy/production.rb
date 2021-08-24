set :deploy_to, "/var/www/#{fetch(:client)}-hmis-production"
set :rails_env, "production"

raise "You must specify DEPLOY_USER" if ENV['DEPLOY_USER'].to_s == ''

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
# set :branch, 'production'

if !ENV['HOSTS'].nil?
  puts "Allowable hosts: #{ENV['HOSTS']}"
end

web_hosts = ENV['HOSTS_WEB'].to_s.split(/,/)
utility_hosts = ENV['HOSTS_UTILITY'].to_s.split(/,/)
cron_host = ENV['HOST_WITH_CRON']

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
