require 'aws-sdk-cloudwatch'
require 'aws-sdk-ecs'
require 'byebug'

# Looks at RAM utilization over the past two weeks and makes recommendations if
# it can

class MemoryAnalyzer
  attr_accessor :cluster_name
  attr_accessor :task_definition_name

  attr_accessor :scheduled_hard_limit
  attr_accessor :scheduled_soft_limit

  attr_accessor :current_soft_limit
  attr_accessor :current_hard_limit

  attr_accessor :recommended_soft_limit
  attr_accessor :recommended_hard_limit

  TWO_WEEKS = 14*24*60*60
  TWO_WEEKS_AGO = (Time.now - TWO_WEEKS).to_date

  # Number of metric values needed before we try to estimate RAM. If metrics
  # come in every 5 minutes, then this number represents
  # (MIN_SAMPLES * 5 / 60 / 24) days of data
  MIN_SAMPLES = 2_000

  class TaskDefinition
    def initialize(name)
      @name = name
      @td = ecs.describe_task_definition(task_definition: name)&.task_definition
    rescue Aws::ECS::Errors::ClientException => e
      raise e unless e.message.match?(/Unable to describe task definition/)
    end

    def exists?
      !@td.nil?
    end

    def version
      @version ||= @td.task_definition_arn.split(/:/).last.to_i
    end

    def hard_limit
      @hard_limit ||= @td.container_definitions.first.memory
    end

    def soft_limit
      @soft_limit ||= @td.container_definitions.first.memory_reservation
    end

    def deployed_at
      @deployed_at ||= Date.parse(@td.container_definitions.first.environment.find { |e| e.name == 'DEPLOYED_AT' }.value)
    end

    def next_name
      @td.task_definition_arn.split(/:/)[0..-2].join(':') + ":#{version-1}"
    end

    private

    define_method(:ecs) { Aws::ECS::Client.new }
  end

  def _ram_settings_havent_changed_in_two_weeks?
    td = TaskDefinition.new(task_definition_name)

    return false unless td.exists?

    softs = Set.new
    hards = Set.new

    self.current_soft_limit = td.soft_limit
    self.current_hard_limit = td.hard_limit

    while td.exists? && td.deployed_at > TWO_WEEKS_AGO
      softs << td.soft_limit
      hards << td.hard_limit
      td = TaskDefinition.new(td.next_name)
    end

    if softs.length == 1 && hards.length == 1
      return true
    end
  end

  def run!
    unless _ram_settings_havent_changed_in_two_weeks?
      puts "[INFO][MEMORY_ANALYZER] Cannot analyze RAM as it has changed in the past two weeks or there's not enough history"
      return
    end

    if _overall_stats.sample_count > MIN_SAMPLES
      puts "[INFO][MEMORY_ANALYZER] With #{_overall_stats.sample_count.to_i} samples, we found #{_overall_stats.average.round(1)}% average memory utilization and #{_overall_stats.maximum.round(1)}% maximum memory utilization"

      # recommend 5% above maximum utilizataion in recent past
      recommended_hard_limit = (current_soft_limit * ((_overall_stats.maximum+5.0) / 100.0)).ceil

      # one standard deviation from the mean
      recommended_soft_limit = (current_soft_limit * ((_overall_stats.average + _overall_stats.stddev)/100.0)).ceil

      puts "[INFO][MEMORY_ANALYZER] Soft limit is #{scheduled_soft_limit} but could be #{recommended_soft_limit}"
      puts "[INFO][MEMORY_ANALYZER] Hard limit is #{scheduled_hard_limit} but could be #{recommended_hard_limit}"
    else
      puts "[INFO][MEMORY_ANALYZER] Skipping memory metric stats since we don't have enough history yet"
      recommended_hard_limit = scheduled_hard_limit
      recommended_soft_limit = scheduled_soft_limit
    end
  end

  def _overall_stats
    @_overall_stats ||= begin

      get = ->(period) do
        cw.get_metric_statistics({
          namespace: "AWS/ECS",
          metric_name: "MemoryUtilization",
          dimensions: [
            {
              name: "ServiceName",
              value: task_definition_name,
            },
            {
              name: "ClusterName",
              value: cluster_name,
            },
          ],
          start_time: (Time.now - TWO_WEEKS),
          end_time: Time.now,
          #period: 15*60, # seconds
          #period: 60*60, # TWO_WEEKS,
          period: period,
          statistics: ["Maximum", "Minimum", "Average", "SampleCount"], # accepts SampleCount, Average, Sum, Minimum, Maximum
          unit: "Percent",
        })
      end

      resp = get.call(60*60)

      if resp.datapoints.length == 0
        puts "[INFO][MEMORY_ANALYZER] No cloudwatch data. We only have it for services anyway."
        return OpenStruct.new(sample_count: 0)
      end

      # This is an estimate, because we can only get a limited set of data
      vals = resp.datapoints.map(&:average)
      len = vals.length
      mean = vals.sum.to_f / len
      stddev = Math.sqrt(vals.inject(0.0) { |s,x| s += (x - mean)**2 } / len)

      resp = get.call(TWO_WEEKS)

      if resp.datapoints.length == 0
        puts "[INFO][MEMORY_ANALYZER] No cloudwatch data. We only have it for services anyway."
        return OpenStruct.new(sample_count: 0)
      end

      OpenStruct.new({
        maximum: resp.datapoints.first.maximum,
        minimum: resp.datapoints.first.minimum,
        average: resp.datapoints.first.average,
        sample_count: resp.datapoints.first.sample_count,
        stddev: stddev,
      })
    end
  rescue Aws::CloudWatch::Errors::InvalidParameterCombination =>  e
    puts "[INFO][MEMORY_ANALYZER] #{e.message}"
    return nil
  end

  define_method(:cw)  { Aws::CloudWatch::Client.new }
end

if ENV['MA_TEST']
  ma = MemoryAnalyzer.new
  ma.cluster_name         = 'openpath'
  ma.task_definition_name = 'qa-warehouse-staging-ecs-web'
  ma.scheduled_hard_limit = 9000
  ma.scheduled_soft_limit = 1800
  ma.run!
end
