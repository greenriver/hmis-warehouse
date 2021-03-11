###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports
  class NumberHoused < ::PublicReports::Report
    acts_as_paranoid

    def title
      _('Number Housed Generator')
    end

    def instance_title
      _('Number Housed Report')
    end

    private def public_s3_directory
      'housed-total-count'
    end

    def url
      public_reports_warehouse_reports_number_housed_index_url(host: ENV.fetch('FQDN'))
    end

    def generate_publish_url
      # TODO: This is the standard S3 public access, it will need to be updated
      # when moved to CloudFront
      if ENV['S3_PUBLIC_URL'].present?
        "#{ENV['S3_PUBLIC_URL']}/#{public_s3_directory}"
      else
        # "http://#{s3_bucket}.s3-website-#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{public_s3_directory}"
        "https://#{s3_bucket}.s3.amazonaws.com/#{public_s3_directory}/index.html"
      end
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
      @filter_object ||= ::Filters::OutflowReport.new.set_from_params(filter['filters'].merge(enforce_one_year_range: false, sub_population: :clients).with_indifferent_access)
    end
  end
end
