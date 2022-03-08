require 'aws-sdk-cloudwatch'
require 'aws-sdk-ecs'
require 'aws-sdk-dynamodb'
require 'amazing_print'

# Looks at RAM utilization over the recent past makes recommendations if
# it can

# rubocop:disable Style/RedundantSelf

class MemoryAnalyzer
  attr_accessor :cluster_name
  attr_accessor :task_definition_name

  attr_accessor :bootstrapped_hard_limit_mb
  attr_accessor :bootstrapped_soft_limit_mb

  attr_accessor :current_soft_limit_mb
  attr_accessor :current_hard_limit_mb

  attr_accessor :last_task_soft_limit_mb
  attr_accessor :last_task_hard_limit_mb

  attr_reader :recommended_soft_limit_mb
  attr_reader :recommended_hard_limit_mb

  DAY = 24 * 60 * 60
  TWO_DAYS_AGO = (Time.now - 2 * DAY).to_date

  DYNAMO_DB_TABLE_NAME = 'deployment-values'.freeze

  RemoteValue = Struct.new(
    :task_definition_name,
    :current_soft_limit_mb,
    :current_hard_limit_mb,
    :recommended_soft_limit_mb,
    :recommended_hard_limit_mb,
    :locked, # set this to 'true' to make this code just use the value in dynamodb
    :updated_at,
    keyword_init: true,
  )

  # Number of metric values needed before we try to estimate RAM. If metrics
  # come in every 5 minutes, then this number represents
  # (MIN_SAMPLES * 5 / 60 / 24) days of data
  MIN_SAMPLES = 288 # ~24 hours

  MIN_RAM_MB = 600
  MAX_RAM_MB = 30_000

  def run!
    if current_values.locked == 'true'
      puts '[INFO][MEMORY_ANALYZER] Using locked values. Not actually analyzing'
      self.recommended_hard_limit_mb = current_values.current_hard_limit_mb.to_i
      self.recommended_soft_limit_mb = current_values.current_soft_limit_mb.to_i
      return
    end

    unless _ram_settings_havent_changed_recently?
      puts "[INFO][MEMORY_ANALYZER] Cannot analyze RAM as it has changed in the past day or there's not enough history"
      self.recommended_hard_limit_mb = scheduled_hard_limit_mb
      self.recommended_soft_limit_mb = scheduled_soft_limit_mb
      return
    end

    if _overall_stats.sample_count > MIN_SAMPLES
      puts "[INFO][MEMORY_ANALYZER] With #{_overall_stats.sample_count.to_i} samples, we found #{_overall_stats.average.round(1)}% average memory utilization and #{_overall_stats.maximum.round(1)}% maximum memory utilization"

      # recommend some percentage above maximum utilization in recent past
      self.recommended_hard_limit_mb = (current_soft_limit_mb * ((_overall_stats.maximum * 4) / 100.0)).ceil

      self.recommended_soft_limit_mb =
        begin
          if task_definition_name.match?(/dj-(all|long)/)
            # Percentage of maximum RAM
            puts '[INFO][MEMORY_ANALYZER] Soft limit 95% of maximum'
            ((current_soft_limit_mb * (_overall_stats.maximum / 100.0)) * 0.95).ceil
          else
            # 1 stddev above mean
            puts '[INFO][MEMORY_ANALYZER] Soft limit via 1 stddev'
            (current_soft_limit_mb * ((_overall_stats.average + 1.0 * _overall_stats.stddev) / 100.0)).ceil
          end
        end

      self.recommended_hard_limit_mb = self.recommended_soft_limit_mb if self.recommended_hard_limit_mb < self.recommended_soft_limit_mb

      puts format('[INFO][MEMORY_ANALYZER] %13s %20s %20s %30s', 'Quota Type', 'Value to Use Now', 'Recommended Value', 'Last Task Definition Value')
      puts format('[INFO][MEMORY_ANALYZER] %13s %20d %20d %30d', 'Hard (MB)', use_memory_analyzer? ? self.recommended_hard_limit_mb : self.scheduled_hard_limit_mb, self.recommended_hard_limit_mb, last_task_hard_limit_mb)
      puts format('[INFO][MEMORY_ANALYZER] %13s %20d %20d %30d', 'Soft (MB)', use_memory_analyzer? ? self.recommended_soft_limit_mb : self.scheduled_soft_limit_mb, self.recommended_soft_limit_mb, last_task_soft_limit_mb)
    else
      puts "[INFO][MEMORY_ANALYZER] Skipping memory metric stats since we don't have enough history yet"
      self.recommended_hard_limit_mb = scheduled_hard_limit_mb
      self.recommended_soft_limit_mb = scheduled_soft_limit_mb
    end

    return unless use_memory_analyzer?

    update_values!
  end

  def use_memory_analyzer?
    true
  end

  # Set the limits on this object and call this method
  def lock!
    update_values!(locked: 'true')
  end

  def recommended_soft_limit_mb= val
    @recommended_soft_limit_mb = _constrain(val)
  end

  def recommended_hard_limit_mb= val
    @recommended_hard_limit_mb = _constrain(val)
  end

  def scheduled_hard_limit_mb
    (current_values.current_hard_limit_mb || bootstrapped_hard_limit_mb).to_i
  end

  def scheduled_soft_limit_mb
    (current_values.current_soft_limit_mb || bootstrapped_soft_limit_mb).to_i
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
      @td.task_definition_arn.split(/:/)[0..-2].join(':') + ":#{version - 1}"
    end

    private

    define_method(:ecs) { Aws::ECS::Client.new }
  end

  def _ram_settings_havent_changed_recently?
    td = TaskDefinition.new(task_definition_name)

    return false unless td.exists?

    self.last_task_soft_limit_mb = td.soft_limit_mb
    self.last_task_hard_limit_mb = td.hard_limit_mb

    softs = Set.new([td.soft_limit_mb])
    hards = Set.new([td.hard_limit_mb])

    self.current_soft_limit_mb = td.soft_limit_mb
    self.current_hard_limit_mb = td.hard_limit_mb

    while td.exists? && td.deployed_at > TWO_DAYS_AGO
      # puts({deployed_at: td.deployed_at, soft: td.soft_limit_mb, hard: td.hard_limit_mb}.ai)
      softs << td.soft_limit_mb
      hards << td.hard_limit_mb
      td = TaskDefinition.new(td.next_name)
    end

    return true if softs.length == 1 && hards.length == 1

    return false
  end

  def _overall_stats
    @_overall_stats ||= begin
      get = ->(period) do
        cw.get_metric_statistics(
          {
            namespace: 'AWS/ECS',
            metric_name: 'MemoryUtilization',
            dimensions: [
              {
                name: 'ServiceName',
                value: task_definition_name,
              },
              {
                name: 'ClusterName',
                value: cluster_name,
              },
            ],
            start_time: (Time.now - DAY),
            end_time: Time.now,
            # period: 15*60, # seconds
            # period: 60*60, # TWO_WEEKS,
            period: period,
            statistics: ['Maximum', 'Minimum', 'Average', 'SampleCount'], # accepts SampleCount, Average, Sum, Minimum, Maximum
            unit: 'Percent',
          },
        )
      end

      puts '[INFO][MEMORY_ANALYZER] Getting metrics'
      resp = get.call(60 * 5)

      if resp.datapoints.empty?
        puts '[INFO][MEMORY_ANALYZER] No cloudwatch data. We only have it for services anyway.'
        return OpenStruct.new(sample_count: 0)
      else
        puts "[INFO][MEMORY_ANALYZER] Got #{resp.datapoints.length} datapoints"
      end

      # This is an estimate, because we can only get a limited set of data
      vals = resp.datapoints.map(&:average)
      len = vals.length
      mean = vals.sum.to_f / len
      stddev = Math.sqrt(vals.inject(0.0) { |s, x| s + (x - mean)**2 } / len)

      resp = get.call(DAY)

      if resp.datapoints.empty?
        puts '[INFO][MEMORY_ANALYZER] No cloudwatch data. We only have it for services anyway.'
        return OpenStruct.new(sample_count: 0)
      end

      OpenStruct.new(
        {
          maximum: resp.datapoints.first.maximum,
          minimum: resp.datapoints.first.minimum,
          average: resp.datapoints.first.average,
          sample_count: resp.datapoints.first.sample_count,
          stddev: stddev,
        },
      )
    end
  rescue Aws::CloudWatch::Errors::InvalidParameterCombination => e
    puts "[INFO][MEMORY_ANALYZER] #{e.message}"
    return nil
  end

  define_method(:table) { @table ||= Aws::DynamoDB::Table.new(DYNAMO_DB_TABLE_NAME) }

  def current_values
    return @current_values unless @current_values.nil?

    val = table.get_item(key: { 'task_definition_name' => task_definition_name }).item

    @current_values = RemoteValue.new(
      {
        'task_definition_name' => task_definition_name,
        'current_soft_limit_mb' => nil,
        'current_hard_limit_mb' => nil,
        'locked' => 'false',
      }.merge(val || {}),
    )
  end

  def update_values!(locked: 'false')
    raise 'You did something wrong. recommended values should be set.' if recommended_soft_limit_mb.nil? || recommended_hard_limit_mb.nil?

    item = current_values.to_h.merge(
      {
        'task_definition_name' => task_definition_name,
        'current_soft_limit_mb' => recommended_soft_limit_mb,
        'current_hard_limit_mb' => recommended_hard_limit_mb,
        'updated_at' => Time.now.to_s,
        'locked' => locked,
      },
    )
    item.delete('recommended_hard_limit_mb')
    item.delete('recommended_soft_limit_mb')
    item.delete(:recommended_hard_limit_mb)
    item.delete(:recommended_soft_limit_mb)
    table.put_item(item: item)
  end

  define_method(:cw) { Aws::CloudWatch::Client.new }
end

if ENV['LOCK_TASK']
  # lock in a custom RAM soft and hard limit
  ma = MemoryAnalyzer.new
  ma.cluster_name         = 'openpath'
  ma.task_definition_name = ENV['LOCK_TASK']
  ma.bootstrapped_hard_limit_mb = ENV.fetch('LOCK_HARD').to_i
  ma.bootstrapped_soft_limit_mb = ENV.fetch('LOCK_SOFT').to_i
  ma.lock!
end
# rubocop:enable Style/RedundantSelf
