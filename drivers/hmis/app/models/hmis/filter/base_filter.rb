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

  # implement in subclass
  # def filter_scope(scope)
  #   scope = ensure_scope(scope)
  #   scope...
  # end

  protected

  # Utility to clean up joins or other things that could cause trouble downstream
  def clean_scope(scope)
    scope.all.klass.where(id: scope.pluck(:id))
  end

  private

  def with_filter(scope, filter)
    # if scope is a class, we are probably missing permission filters
    scope = scope.all unless scope.is_a?(ActiveRecord::Relation)
    raise 'must be a relation' unless scope.is_a?(ActiveRecord::Relation)

    return scope unless input.respond_to?(filter) && input.send(filter)&.present?

    yield
  end

  # IMPORTANT: ensures scope is always a relation. Prevents accidental scope loss if passed a class instead of scope
  def ensure_scope(scope)
    scope.current_scope || scope.all
  end
end
