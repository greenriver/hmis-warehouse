###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class NumberHoused < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Number Housed Report Generator')
    end

    def instance_title
      _('Number Housed Report')
    end

    private def public_s3_directory
      'housed-total-count'
    end

    def url
      public_reports_warehouse_reports_number_housed_index_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    private def controller_class
      PublicReports::WarehouseReports::NumberHousedController
    end

    def run_and_save!
      start_report
      pre_calculate_data
      complete_report
    end

    private def chart_data
      {
        count: housed_total_count,
        date_range: filter_object.date_range_words,
      }.to_json
    end

    private def pre_calculate_data
      update(precalculated_data: chart_data)
    end

    # NOTE: this count is equivalent to OutflowReport.exits_to_ph
    private def housed_total_count
      outflow = GrdaWarehouse::WarehouseReports::OutflowReport.new(filter_object, user)
      outflow.exits_to_ph.count
    end

    def filter_object
      @filter_object ||= ::Filters::OutflowReport.new(user_id: user.id).set_from_params(filter['filters'].merge(enforce_one_year_range: false, sub_population: :clients).with_indifferent_access)
    end
  end
end
