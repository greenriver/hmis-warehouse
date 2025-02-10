class Filters::Criteria::FilterForDataSources < Filters::Criteria::Base
  LEVEL = :project

  def applies?
    config.data_source_ids.present? && user.report_filter_visible?(:data_source_ids)
  end

  def apply(scope)
    scope.in_data_source(input.data_source_ids).
      joins(:data_source).
      merge(GrdaWarehouse::DataSource.viewable_by(user))
  end
end
