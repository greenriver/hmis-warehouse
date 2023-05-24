###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::BaseFilter
  attr_accessor :input
  def initialize(input)
    self.input = input
  end

  def filter_scope(scope)
    scope
  end

  protected

  # Utility to clean up joins or other things that could cause trouble downstream
  def clean_scope(scope)
    scope.all.klass.where(id: scope.pluck(:id))
  end

  private

  def with_filter(scope, input, filter)
    return scope unless input.respond_to?(filter) && input.send(filter)&.present?

    yield
  end
end
