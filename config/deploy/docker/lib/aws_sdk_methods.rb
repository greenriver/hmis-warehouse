module AwsSdkMethods
  define_method(:iam) { Aws::IAM::Client.new }
  define_method(:elbv2) { Aws::ElasticLoadBalancingV2::Client.new }
  define_method(:ecr) { Aws::ECR::Client.new }
  define_method(:secretsmanager) { Aws::SecretsManager::Client.new }
  define_method(:ecs) { Aws::ECS::Client.new }
  define_method(:autoscaling) { Aws::AutoScaling::Client.new}
  define_method(:ec2) { Aws::EC2::Client.new}
  define_singleton_method(:cloudwatchevents) { Aws::CloudWatchEvents::Client.new }
  define_method(:cloudwatchevents) { Aws::CloudWatchEvents::Client.new }
  define_method(:cw)  { Aws::CloudWatch::Client.new }
  define_method(:cwl) { Aws::CloudWatchLogs::Client.new(profile: aws_profile) }

end
