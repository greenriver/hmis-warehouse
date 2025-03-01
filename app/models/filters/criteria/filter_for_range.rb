# frozen_string_literal: true

class Filters::Criteria::FilterForRange < Filters::Criteria::Base
  def applies?
    config.include_date_range
  end

  def apply(scope)
    scope = super(scope)
    scope = scope.open_between(start_date: input.start_date, end_date: input.end_date)
    return scope unless input.require_service_during_range

    scope.with_service_between(start_date: input.start_date, end_date: input.end_date)
  end
end
