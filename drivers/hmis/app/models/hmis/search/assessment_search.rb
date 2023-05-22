###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Search::AssessmentSearch
  attr_accessor :input
  def initialize(input)
    self.input = input
  end

  def results(scope)
    scope.
      yield_self(&method(:with_roles))
  end

  protected

  def with_roles(scope)
    with_filter(scope, input, :roles) { scope.with_role(input.roles) }
  end

  private

  def with_filter(scope, input, filter)
    return scope unless input.respond_to?(filter) && input.send(filter)&.present?

    yield
  end
end
