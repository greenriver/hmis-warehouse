###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module BostonReports::WarehouseReports
  class CommunityOfOriginsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include BaseFilters

    before_action :set_report
    before_action :set_pdf_export
    def index
      render layout: 'report_with_map'
    end

    def across_the_country_data
      percent_of_clients_data = [
        { name: 'Massachusetts', percent: 0.1 },
        { name: 'Utah', percent: 0.75 },
        { name: 'Idaho', percent: 0.34 },
        { name: 'Vermont', percent: 0.042 },
        { name: 'Connecticut', percent: 0.9 },
        { name: 'Maine', percent: 0.6 },
        { name: 'New Hampshire', percent: 0.25 },
        { name: 'Rhode Island', percent: 0.03 },
      ].map do |d|
        d.merge({ display_percent: ActiveSupport::NumberHelper.number_to_percentage(d[:percent] * 100, precision: 1, strip_insignificant_zeros: true) })
      end
      percent_names = percent_of_clients_data.map { |d| d[:name] }
      GrdaWarehouse::Shape::State.where(name: percent_names).map do |state|
        state.geo_json_properties.merge(percent_of_clients_data.select { |d| d[:name] == state.name }.first)
      end.sort_by { |d| d[:percent] }.reverse
    end
    helper_method :across_the_country_data

    def top_zip_codes_data(scope)
      scope.map do |shape|
        { zip_code: shape.zcta5ce10, percent: rand(0..0.2) }
      end
    end
    helper_method :top_zip_codes_data

    def zip_code_shape_data(scope)
      GrdaWarehouse::Shape.geo_collection_hash(scope)
    end
    helper_method :zip_code_shape_data

    def zip_code_fake_scope
      # GrdaWarehouse::Shape::ZipCode.my_state.last(20)
      GrdaWarehouse::Shape::ZipCode.my_state.sample(20)
    end
    helper_method :zip_code_fake_scope

    def zip_code_colors
      [
        { color: '#BF216B', range: [0.02] },
        { color: '#F22797', range: [0.02, 0.05] },
        { color: '#F2BC1B', range: [0.05, 0.1] },
        { color: '#F26A1B', range: [0.1, 0.15] },
        { color: '#F5380E', range: [0.15] },
      ]
    end
    helper_method :zip_code_colors

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      BostonReports::CommunityOfOrigin
    end

    def filter_params
      return report_class.default_filter_options unless params[:filters].present?

      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = BostonReports::DocumentExports::CommunityOfOriginPdfExport.new
    end
  end
end
