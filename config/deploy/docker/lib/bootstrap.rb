# Makes target group, attaches it to the load balancer, and sets up DNS

require 'aws-sdk-route53'
require 'aws-sdk-elasticloadbalancingv2'
#require 'byebug'

class Bootstrap
  attr_accessor :host
  attr_accessor :name
  attr_accessor :load_balancer_name

  AWS_PROFILE = ENV.fetch('AWS_PROFILE')

  def initialize(host:, name:)
    self.host = host
    self.name = name
    self.load_balancer_name = 'openpath-ecs'
  end

  def run!
    _sanity_check!
    make_target_group!
    modify_attributes!
    attach_to_listener!
    dns!
  end

  def make_target_group!
    puts "Making a target group called #{name}. Harmless to run multiple times."

    elbv2.create_target_group(
      name: name,
      vpc_id: vpc_id,
      protocol: "HTTPS",
      port: 443,
      health_check_protocol: "HTTPS",
      health_check_enabled: true,
      health_check_path: "/system_status/operational",
      health_check_interval_seconds: 60,
      health_check_timeout_seconds: 5,
      healthy_threshold_count: 2,
      unhealthy_threshold_count: 3,
      matcher: { http_code: "200" },
      target_type: "instance",
    )
  end

  def modify_attributes!
    puts "Configuring target group. Harmless to run multiple times."

    elbv2.modify_target_group_attributes(
      target_group_arn: target_group_arn,
      attributes: [
        {
          key: 'load_balancing.algorithm.type',
          value: 'least_outstanding_requests',
        },
        {
          key: 'deregistration_delay.timeout_seconds',
          value: '30',
        }
      ]
    )
  end

  # Make a rule for the load balancer so it knows this host maps to this target
  # group
  def attach_to_listener!
    rules = elbv2.describe_rules(listener_arn: listener_arn).rules

    existing_priorities = Set.new

    rules.each do |rule|
      existing_priorities << rule.priority
      rule.actions.each do |action|
        if action.target_group_arn == target_group_arn
          puts "Found an existing rule for this target group. Not adding a new one"
          return
        end
      end
    end

    puts "Adding target group to the load balancer via a rule"

    priority = nil
    while priority.nil?
      try = Random.rand(100).to_s
      unless existing_priorities.include?(try)
        priority = try
      end
    end

    elbv2.create_rule(
      listener_arn: listener_arn,
      priority: priority,
      conditions: [
        {
          field: "host-header",
          host_header_config: {
            values: [
              host
            ]
          }
        }
      ],
      actions: [
        {
          type: "forward",
          target_group_arn: target_group_arn,
          forward_config: {
            target_groups: [
              {
                target_group_arn: target_group_arn,
                weight: 1
              }
            ],
            target_group_stickiness_config: {
              enabled: false,
              duration_seconds: 1200
            }
          }
        }
      ]
    )
  end

  def dns!
    puts "Setting up DNS record. Harmless to run multiple times."

    route53.change_resource_record_sets(
      hosted_zone_id: hosted_zone,
      change_batch: {
        comment: "Added by script",
        changes: [
          {
            action:  "UPSERT",
            resource_record_set: {
              name: host,
              type: "CNAME",
              ttl:  300,
              resource_records: [
                {
                  value: load_balancer_cname,
                }
              ]
            }
          }
        ]
      }
    )

    puts "Try:\ndig #{host} +trace\nYou should get some NS records very soon."
  end

  private

  def _sanity_check!
    puts "Checking things look okay before proceeding"

    raise "No load balancer!" if load_balancer_arn.nil?

    raise "No load balancer CNAME!" if load_balancer_cname.nil?

    raise "No listener!" if listener_arn.nil?

    raise "No hosted zone! Does your host name match what's available in our account?" if hosted_zone.nil?

    if name.length > 32
      raise "Cannot have a name longer than 32 characters: #{name}"
    end

    if !name.match?(/ecs/) || !name.match?(/staging|production/) || !name.match(/cas|warehouse|hmis/)
      raise "Please name your target groups with an environment, the client, and app, and the token 'ecs'"
    end
  end


  def load_balancer_arn
    return @load_balancer_arn unless @load_balancer_arn.nil?

    elbv2.describe_load_balancers.each do |set|
      set.load_balancers.each do |lb|
        if lb.load_balancer_name == load_balancer_name
          @load_balancer_arn = lb.load_balancer_arn
          @vpc_id = lb.vpc_id
          return @load_balancer_arn
        end
      end
    end

    return nil
  end

  def target_group_arn
    @target_group_arn ||=
      elbv2.describe_target_groups(names: [name]).to_h[:target_groups].first[:target_group_arn]
  end

  def listener_arn
    return @listener_arn unless @listener_arn.nil?

    results = elbv2.describe_listeners(
      load_balancer_arn: load_balancer_arn
    )

    results.each do |set|
      set.listeners.each do |l|
        if l.port == 443
          return @listener_arn = l[:listener_arn]
        end
      end
    end
  end

  def hosted_zone
    return @hosted_zone unless @hosted_zone.nil?

    zone = route53.list_hosted_zones_by_name.to_h[:hosted_zones].find do |zone|
      host.end_with?(zone[:name][0..-2])
    end

    @hosted_zone = zone[:id]
  end

  def load_balancer_cname
    @load_balancer_cname ||=
      elbv2.describe_load_balancers(
        names: [load_balancer_name]
      ).load_balancers.first.dns_name
    #| jq '.LoadBalancers[].DNSName' | sed 's/"//g'`
  end

  def vpc_id
    load_balancer_arn
    @vpc_id
  end

  define_method(:elbv2) { Aws::ElasticLoadBalancingV2::Client.new(profile: AWS_PROFILE) }
  define_method(:route53) { Aws::Route53::Client.new(profile: AWS_PROFILE) }
end
