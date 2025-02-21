class Filters::Criteria::Base
  attr_accessor :input, :config

  def id = Filters::Criteria::IDS_BY_CLASS.fetch(self.class)
  def arel = Hmis::ArelHelper.instance
  def user = input.user

  def initialize(input:, config: nil)
    @input = input
    @config = config || Filters::Criteria::Configuration.new
  end

  # FIXME, probably doesn't belong here
  def add_alternative(scope, alternative)
    if scope.nil?
      alternative
    else
      scope.or(alternative)
    end
  end
end
