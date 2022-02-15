require 'aws-sdk-iam'
require 'aws-sdk-elasticloadbalancingv2'
require 'aws-sdk-ecr'
require 'aws-sdk-ecs'
require 'aws-sdk-secretsmanager'
require 'aws-sdk-autoscaling'
require 'aws-sdk-ec2'
require 'aws-sdk-cloudwatchevents'
require 'aws-sdk-cloudwatch'
require 'aws-sdk-cloudwatchlogs'

module AwsSdkHelpers
  module ClientMethods
    define_singleton_method(:iam) { Aws::IAM::Client.new }
    define_singleton_method(:elbv2) { Aws::ElasticLoadBalancingV2::Client.new }
    define_singleton_method(:ecr) { Aws::ECR::Client.new }
    define_singleton_method(:ecs) { Aws::ECS::Client.new }
    define_singleton_method(:secretsmanager) { Aws::SecretsManager::Client.new }
    define_singleton_method(:autoscaling) { Aws::AutoScaling::Client.new}
    define_singleton_method(:ec2) { Aws::EC2::Client.new}
    define_singleton_method(:cloudwatchevents) { Aws::CloudWatchEvents::Client.new }
    define_singleton_method(:cw)  { Aws::CloudWatch::Client.new }
    def self.cwl(profile = nil)
      profile ||= AwsSdkHelpers::Helpers.cluster_name
      Aws::CloudWatchLogs::Client.new(profile: profile)
    end

    define_method(:iam)              { AwsSdkHelpers::ClientMethods.iam }
    define_method(:elbv2)            { AwsSdkHelpers::ClientMethods.elbv2 }
    define_method(:ecr)              { AwsSdkHelpers::ClientMethods.ecr }
    define_method(:ecs)              { AwsSdkHelpers::ClientMethods.ecs }
    define_method(:secretsmanager)   { AwsSdkHelpers::ClientMethods.secretsmanager }
    define_method(:autoscaling)      { AwsSdkHelpers::ClientMethods.autoscaling }
    define_method(:ec2)              { AwsSdkHelpers::ClientMethods.ec2 }
    define_method(:cloudwatchevents) { AwsSdkHelpers::ClientMethods.cloudwatchevents }
    define_method(:cw)               { AwsSdkHelpers::ClientMethods.cw }
    define_method(:cwl)              { AwsSdkHelpers::ClientMethods.cwl(
      profile: respond_to?(:_cluster_name) ? _cluster_name : AwsSdkHelpers::Helpers.cluster_name,
    ) }
  end

  module Helpers
    include AwsSdkHelpers::ClientMethods

    def self.cluster_name
      ENV.fetch('CLUSTER_NAME', ENV.fetch('AWS_CLUSTER', ENV.fetch('AWS_PROFILE', ENV.fetch('AWS_VAULT', ''))))
    end
    def _cluster_name
      AwsSdkHelpers::Helpers.cluster_name
    end

    def self.capacity_providers(cluster)
      r = {}
      capacity_provider_names = AwsSdkHelpers::ClientMethods.ecs.describe_clusters(clusters: [cluster]).clusters.first.capacity_providers
      AwsSdkHelpers::ClientMethods.ecs.describe_capacity_providers(capacity_providers: capacity_provider_names).capacity_providers.map do |capacity_provider|
        asg_name = capacity_provider.auto_scaling_group_provider.auto_scaling_group_arn.split('/').last
        asg = AwsSdkHelpers::ClientMethods.autoscaling.describe_auto_scaling_groups(auto_scaling_group_names: [ asg_name ]).auto_scaling_groups.first

        launch_template_id = asg.mixed_instances_policy.launch_template.launch_template_specification.launch_template_id
        launch_template_versions = AwsSdkHelpers::ClientMethods.ec2.describe_launch_template_versions(launch_template_id: launch_template_id)

        ami_id = launch_template_versions.launch_template_versions[0].launch_template_data.image_id

        r[capacity_provider.name] = {
          name: capacity_provider.name,
          ami_id: ami_id
        }
      end
    end
    def _capacity_providers(cluster = nil)
      cluster ||= _cluster_name
      @capacity_providers ||= AwsSdkHelpers::Helpers.capacity_providers(cluster)
    end

    def self.default_placement_constraints(ami_id:)
      [
        {
          expression: "attribute:ecs.ami-id == #{ami_id}",
          type: 'memberOf'
        },
      ]
    end
    def _default_placement_constraints(capacity_provider_name: '', ami_id: '')
      if ami_id.empty?
        unless capacity_provider_name.empty?
          ami_id = _capacity_providers[capacity_provider_name][:ami_id]
        else
          ami_id = _capacity_providers.first[:ami_id]
        end
      end
      AwsSdkHelpers::Helpers.default_placement_constraints(ami_id: ami_id)
    end


    def _spot_capacity_provider_name
      _capacity_providers.find { |cp| cp[:name].match(/spt-v2/) }[:name]
    end

    def _on_demand_capacity_provider_name
      _capacity_providers.find { |cp| cp[:name].match(/ondemand-v2/) }[:name]
    end

  end
end
