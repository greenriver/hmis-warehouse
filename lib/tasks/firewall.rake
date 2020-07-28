namespace :firewall do

  desc "whitelist IPs for db access on pgbouncer instance."
  task :update, [] => [:environment] do |t, args|
    firewall = DbFirewallMaintainer.new

    #ap firewall.desired_creds
    # puts "------"
    # puts firewall.send(:bouncer_userlist)
    # puts "------"
    # puts firewall.update!

    # firewall.add!(
    #   ip: '8.8.8.8/32',
    #   description: 'testing',
    # )

    #ap firewall.list
    firewall.push_bouncer_credentials!

    #ap firewall.tags

    #firewall.expire!

    #ap DbFirewallMaintainer.new.list
  end
end
