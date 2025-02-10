class Filters::Criteria::Base
  def self.for_input(input:, config: nil)
    criteria = new(input: input, config: config)
    criteria.applies? ? criteria : nil
  end

  attr_accessor :input, :config
  def initialize(input:, config: nil)
    @input = input
    @config = config || Filters::Criteria::Configuration.new
  end

  def id
    self.class.name.demodulize.underscore
  end

  def hud?
    self.class::IS_HUD
  end

  def level
    case self.class::LEVEL
    when :client, :project
      self.class::LEVEL
    else
      raise NotImplementedError, "#{self.class} must define LEVEL"
    end
  end

  def project_level?
    level == :project
  end

  def client_level?
    level == :client
  end

  def arel
    Hmis::ArelHelper.instance
  end

  # fixme
  def add_alternative(scope, alternative)
    if scope.nil?
      alternative
    else
      scope.or(alternative)
    end
  end

  def user
    input.user
  end
end
