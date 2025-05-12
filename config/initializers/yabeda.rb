Yabeda.configure do
  default_tag :rails_env, Rails.env
  default_tag :app, 'warehouse'
  default_tag :tenant, ENV.fetch('CLIENT', 'unknown-client-set-CLIENT-env-var')
  default_tag :fqdn, ENV.fetch('FQDN', 'unknown-instance-set-FQDN-env-var')
end
