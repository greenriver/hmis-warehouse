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

  # FIXME, probably doesn't belong here
  private def multi_racial_clients(include_hispanic_latinaeo: false)
    # Looking at all races with responses of 1, where we have a sum > 1
    columns = [
      arel.c_t[:AmIndAKNative],
      arel.c_t[:Asian],
      arel.c_t[:BlackAfAmerican],
      arel.c_t[:NativeHIPacific],
      arel.c_t[:White],
      arel.c_t[:MidEastNAfrican],
    ]
    columns << arel.c_t[:HispanicLatinaeo] if include_hispanic_latinaeo

    config.report_scope_source.where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
  end
end
