class Filters::Criteria::Base
  attr_accessor :input, :config
  def initialize(input:, config: nil)
    @input = input
    @config = config || Filters::Criteria::Configuration.new
  end

  def id
    self.class.name.demodulize.underscore
  end

  def arel
    Hmis::ArelHelper.instance
  end

  # FIXME, probably doesn't belong here
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
