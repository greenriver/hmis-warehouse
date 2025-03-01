# frozen_string_literal: true

class Filters::Criteria::FilterForDataSources < Filters::Criteria::Base
  def applies?
    input.data_source_ids.present? && user.report_filter_visible?(:data_source_ids)
  end

  def apply(scope)
    scope = super(scope)
    scope.in_data_source(input.data_source_ids).
      joins(:data_source).
      merge(GrdaWarehouse::DataSource.viewable_by(user))
  end
end
