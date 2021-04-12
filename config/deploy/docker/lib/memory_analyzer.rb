require 'aws-sdk-cloudwatch'
require 'aws-sdk-ecs'
require 'aws-sdk-dynamodb'
require 'amazing_print'

# Looks at RAM utilization over the past two weeks and makes recommendations if
# it can

class MemoryAnalyzer
  attr_accessor :cluster_name
  attr_accessor :task_definition_name

  attr_accessor :scheduled_hard_limit_mb
  attr_accessor :scheduled_soft_limit_mb

  attr_accessor :current_soft_limit_mb
  attr_accessor :current_hard_limit_mb

  TWO_WEEKS = 14*24*60*60
  TWO_WEEKS_AGO = (Time.now - TWO_WEEKS).to_date

  DYNAMO_DB_TABLE_NAME = 'deployment-values'

  RemoteValue = Struct.new(
    :task_definition_name,
    :current_soft_limit_mb,
    :current_hard_limit_mb,
    :recommended_soft_limit_mb,
    :recommended_hard_limit_mb,
    :locked, # set this to 'true' to make this code just use the value in dynamodb
    :updated_at,
    keyword_init: true
  )

  # Number of metric values needed before we try to estimate RAM. If metrics
  # come in every 5 minutes, then this number represents
  # (MIN_SAMPLES * 5 / 60 / 24) days of data
  MIN_SAMPLES = 2_000

  MIN_RAM_MB = 100
  MAX_RAM_MB = 16_000

  def run!
    if current_values.locked == 'true'
      puts "[INFO][MEMORY_ANALYZER] Using locked values. Not actually analyzing"
      self.recommended_hard_limit_mb = current_values.current_hard_limit_mb.to_i
      self.recommended_soft_limit_mb = current_values.current_soft_limit_mb.to_i
      return
    end

    unless _ram_settings_havent_changed_in_two_weeks?
      puts "[INFO][MEMORY_ANALYZER] Cannot analyze RAM as it has changed in the past two weeks or there's not enough history"
      self.recommended_hard_limit_mb = (current_values.current_hard_limit_mb || scheduled_hard_limit_mb).to_i
      self.recommended_soft_limit_mb = (current_values.current_soft_limit_mb || scheduled_soft_limit_mb).to_i
      return
    end

    if _overall_stats.sample_count > MIN_SAMPLES
      puts "[INFO][MEMORY_ANALYZER] With #{_overall_stats.sample_count.to_i} samples, we found #{_overall_stats.average.round(1)}% average memory utilization and #{_overall_stats.maximum.round(1)}% maximum memory utilization"

      # recommend 5% above maximum utilization in recent past
      self.recommended_hard_limit_mb = (current_soft_limit_mb * ((_overall_stats.maximum+5.0) / 100.0)).ceil

      # nsd standard deviations from the mean.
      # 7 out of 63 task definitions had RAM problems when deployed to all
      # staging installations with 1 stddev. All were delayed jobs.
      nsd = task_definition_name.match?(/dj-(all|long)/) ? 1.25 : 1.0
      self.recommended_soft_limit_mb = (current_soft_limit_mb * ((_overall_stats.average + nsd * _overall_stats.stddev)/100.0)).ceil

      puts "[INFO][MEMORY_ANALYZER] Soft limit_mb is #{scheduled_soft_limit_mb} but could be #{recommended_soft_limit_mb}"
      puts "[INFO][MEMORY_ANALYZER] Hard limit_mb is #{scheduled_hard_limit_mb} but could be #{recommended_hard_limit_mb}"
    else
      puts "[INFO][MEMORY_ANALYZER] Skipping memory metric stats since we don't have enough history yet"
      self.recommended_hard_limit_mb = (current_values.current_hard_limit_mb || scheduled_hard_limit_mb).to_i
      self.recommended_soft_limit_mb = (current_values.current_soft_limit_mb || scheduled_soft_limit_mb).to_i
    end

    update_values!
  end

  # Set the limits on this object and call this method
  def lock!
    update_values!(locked: 'true')
  end

  def recommended_soft_limit_mb= val
    @recommended_soft_limit_mb = _constrain(val)
  end

  def recommended_soft_limit_mb
    @recommended_soft_limit_mb
  end

  def recommended_hard_limit_mb= val
    @recommended_hard_limit_mb = _constrain(val)
  end

  def recommended_hard_limit_mb
    @recommended_hard_limit_mb
  end

  private

  def _constrain val
    if val > MAX_RAM_MB
      MAX_RAM_MB
    elsif val < MIN_RAM_MB
      MIN_RAM_MB
    else
      val
    end
  end

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

    def hard_limit_mb
      @hard_limit_mb ||= @td.container_definitions.first.memory
    end

    def soft_limit_mb
      @soft_limit_mb ||= @td.container_definitions.first.memory_reservation
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

    self.current_soft_limit_mb = td.soft_limit_mb
    self.current_hard_limit_mb = td.hard_limit_mb

    while td.exists? && td.deployed_at > TWO_WEEKS_AGO
      softs << td.soft_limit_mb
      hards << td.hard_limit_mb
      td = TaskDefinition.new(td.next_name)
    end

    if softs.length == 1 && hards.length == 1
      return true
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

      # This is an estimate, because we can only get a limit_mbed set of data
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

  define_method(:table) { @stored_values ||= Aws::DynamoDB::Table.new(DYNAMO_DB_TABLE_NAME) }

  def current_values
    return @current_values unless @current_values.nil?

    val = table.get_item(key: { 'task_definition_name' => task_definition_name }).item

    @current_values = RemoteValue.new({
      'task_definition_name'      => task_definition_name,
      'current_soft_limit_mb'     => nil,
      'current_hard_limit_mb'     => nil,
      'locked'                    => 'false',
    }.merge(val || {}))
  end

  def update_values!(locked: 'false')
    if recommended_soft_limit_mb.nil? || recommended_hard_limit_mb.nil?
      raise "You did something wrong. recommended values should be set."
    end

    item = current_values.to_h.merge({
      'task_definition_name'  => task_definition_name,
      'current_soft_limit_mb' => recommended_soft_limit_mb,
      'current_hard_limit_mb' => recommended_hard_limit_mb,
      'updated_at'            => Time.now.to_s,
      'locked'                => locked,
    })
    item.delete('recommended_hard_limit_mb')
    item.delete('recommended_soft_limit_mb')
    item.delete(:recommended_hard_limit_mb)
    item.delete(:recommended_soft_limit_mb)
    table.put_item(item: item)
  end

  define_method(:cw)  { Aws::CloudWatch::Client.new }
end

if ENV['LOCK_TASK']
  # lock in a custom RAM soft and hard limit
  ma = MemoryAnalyzer.new
  ma.cluster_name         = 'openpath'
  ma.task_definition_name = ENV['LOCK_TASK']
  ma.scheduled_hard_limit_mb = ENV.fetch('LOCK_HARD').to_i
  ma.scheduled_soft_limit_mb = ENV.fetch('LOCK_SOFT').to_i
  ma.lock!
end
