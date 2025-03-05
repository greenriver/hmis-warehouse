# frozen_string_literal: true

class Filters::Criteria::FilterForChronicAtEntry < Filters::Criteria::Base
  def applies? = config.chronic_at_entry && input.chronic_status

  def apply(scope)
    scope = super(scope)
    scope.joins(enrollment: :ch_enrollment).merge(GrdaWarehouse::ChEnrollment.chronically_homeless)
  end
end
