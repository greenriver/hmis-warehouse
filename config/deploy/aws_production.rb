set :deploy_to, "/var/www/#{fetch(:client)}-hmis-production"
set :rails_env, "production"

raise "You must specify DEPLOY_USER" if ENV['DEPLOY_USER'].to_s == ''


# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'master'

puts "Allowable hosts: #{ENV['HOSTS']}"
puts "Hosts specified for deployment: #{ENV['HOST1']} #{ENV['HOST2']} #{ENV['HOST3']}"

server ENV['HOST1'], user: ENV['DEPLOY_USER'], roles: %w{app db web job cron}, port: fetch(:ssh_port)
server ENV['HOST2'], user: ENV['DEPLOY_USER'], roles: %w{app web job}, port: fetch(:ssh_port)
server ENV['HOST3'], user: ENV['DEPLOY_USER'], roles: %w{app web job}, port: fetch(:ssh_port)

set :linked_dirs, fetch(:linked_dirs, []).push('certificates', 'key', '.well_known', 'challenge')
set :linked_files, fetch(:linked_files, []).push('config/letsencrypt_plugin.yml')
