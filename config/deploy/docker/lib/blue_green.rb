require 'aws-sdk-elasticloadbalancingv2'

# This class helps coordinate with the HMIS frontend (if one exists) to make
# both systems go live at roughly the same time.
#
# If there is only one target group, this should behave like it did previously.
class BlueGreen
  attr_accessor :target_group_name

  def initialize(target_group_name)
    self.target_group_name = target_group_name
  end

  # Deploy to preview if bluegreen is set up, otherwise deploy to the only
  # target group available
  def target_group_to_deploy_to
    return target_groups[0] if target_groups.length == 1

    stable_target_group_empty? and puts "[WARN] Looks like this is your first deployment. It won't go live until you deploy the HMIS front-end"

    puts '[INFO] Deploying to the preview target group since bluegreen is detected'

    if ENV['DEPLOY_TO_STABLE'] == 'true'
      stable_target_group
    else
      preview_target_group
    end
  end

  def check!
    # raise 'target groups are not properly labeled yet. Deploy the HMIS front-end and try again' if preview_target_group_arn.nil? && target_groups.length > 1

    raise "You shouldn't have zero target groups for #{target_group_name}" if target_groups.empty?

    raise "You shouldn't have more than 2 target groups" if target_groups.length > 2

    return unless target_groups.length == 2

    # For bluegreen enabled deployments there are more checks
    raise 'The number of target groups should match the number of listener rules when bluegreen is enabled' if listener_rules.length != 2 && !preview_target_group_arn.nil?

    preview = listener_rules.find { |lr| lr.blue_green_state == 'preview' }
    stable = listener_rules.reject { |lr| lr.blue_green_state == 'preview' }.first
    listener_rule_not_sane = preview.priority.to_i > stable.priority.to_i
    raise 'The preview listener rule should have a smaller priority number (i.e. higher priority)' if listener_rule_not_sane
  end

  def preview_target_group
    target_groups.find { |tg| tg.blue_green_state == 'preview' }
  end

  def stable_target_group
    target_groups.find { |tg| tg.blue_green_state == 'stable' || tg.blue_green_state.nil? }
  end

  def listener_rules_summary
    listener_rules.map do |lr|
      condition_that_matters = lr.conditions.select(&:http_header_config).map(&:http_header_config).map { |x| { x.http_header_name => x.values.first } }.first
      {
        target_group: lr.actions.first.target_group_arn,
        priority: lr.priority,
        conditions: condition_that_matters,
      }
    end
  end

  private

  def stable_target_group_empty?
    resp = elbv2.describe_target_health(target_group_arn: stable_target_group.target_group_arn)

    resp.target_health_descriptions.empty?
  end

  def listener_rules
    return @listener_rules unless @listener_rules.nil?

    listener_arn = target_group_name.match?(/ost/) ? ENV.fetch('ALTERNATE_LISTENER_ARN') : ENV.fetch('LISTENER_ARN')
    results = elbv2.describe_rules(listener_arn: listener_arn)

    @listener_rules = []

    results.each do |page|
      @listener_rules += page.rules.filter_map do |lr|
        resp = elbv2.describe_tags(resource_arns: [lr.rule_arn])
        tags = tags_as_hash(resp.tag_descriptions[0].tags)

        relevant = tags['BlueGreenGroup'] == target_group_name

        if relevant
          lr.define_singleton_method(:tags) { tags }
          lr.define_singleton_method(:blue_green_group) { tags['BlueGreenGroup'] }
          lr.define_singleton_method(:blue_green_state) { tags['BlueGreenState'] }
          lr
        end
      end
    end

    @listener_rules
  end

  # Relevant target groups annotated with bluegreen information and tags
  def target_groups
    return @target_groups unless @target_groups.nil?

    results = elbv2.describe_target_groups

    @target_groups = []

    results.each do |page|
      @target_groups += page.target_groups.filter_map do |tg|
        # This speeds thing up since all the relevant target groups start with
        # the same characters
        next unless tg.target_group_name.start_with?(target_group_name[0..5])

        resp = elbv2.describe_tags(resource_arns: [tg.target_group_arn])
        tags = tags_as_hash(resp.tag_descriptions[0].tags)

        relevant = tags['BlueGreenGroup'] == target_group_name || tg.target_group_name == target_group_name

        if relevant
          tg.define_singleton_method(:tags) { tags }
          tg.define_singleton_method(:blue_green_group) { tags['BlueGreenGroup'] }
          tg.define_singleton_method(:blue_green_state) { tags['BlueGreenState'] }
          tg
        end
      end
    end

    @target_groups
  end

  def elbv2
    Aws::ElasticLoadBalancingV2::Client.new
  end

  def tags_as_hash(tags)
    tags.map do |t|
      [t.key, t.value]
    end.to_h
  end
end

if ENV['RUN'] == 'true'
  qa = BlueGreen.new('qa-warehouse-staging-ecs')
  qa.check!

  hmis = BlueGreen.new('qa-hmis-fe-hmis-staging-ecs')
  hmis.check!
end
