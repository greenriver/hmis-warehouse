###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports::PublicReportsControllerConcern
  extend ActiveSupport::Concern
  included do
    before_action :set_report, except: [:index, :new, :create]
    before_action :ignore_mini_profiler, only: [:raw, :overall, :housed, :individuals, :adults_with_children, :veterans]

    helper_method :path_to_report
    helper_method :path_to_edit

    def index
      @report = report_source.new
      @filter = filter_class.new(user_id: current_user.id).set_from_params(filter_params[:filters])
      @reports = report_scope.diet.order(id: :desc).page(params[:page]).per(25)
    end

    def create
      @filter = filter_class.new(user_id: current_user.id).set_from_params(filter_params[:filters])
      options = {
        start_date: @filter.start,
        end_date: @filter.end,
        filter: @filter.for_params,
        user_id: current_user.id,
        state: :queued,
      }
      @report = report_source.create(options)
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: path_to_report_index)
    end

    def update
      version_slug = params.dig(:public_report, :version_slug)
      if params[:public_report]&.key?(:version_slug)
        @report.update(version_slug: version_slug)
        respond_with(@report, location: path_to_report)
      elsif params.dig(:public_report, :published_url).present?
        @report.delay.publish!
        flash[:notice] = 'Report publishing queued, please check the public link in a few minutes.'
        respond_with(@report, location: path_to_report)
      else
        redirect_to(action: :edit)
      end
    end

    def raw
      render(layout: 'raw_public_report')
    end

    def show
      redirect_to action: :edit unless @report.published?
    end

    def edit
      redirect_to action: :show if @report.published?
    end

    def destroy
      @report.destroy
      respond_with(@report)
    end

    def filter_params
      options = params.permit(
        filters: [
          :start,
          :end,
          :hoh_only,
          coc_codes: [],
          project_types: [],
          project_type_numbers: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
      options = default_filter_options if options.blank?
      options[:filters][:enforce_one_year_range] = false
      options
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def default_filter_options
      {
        filters: {
          start: 4.years.ago.beginning_of_year.to_date,
          end: 1.years.ago.end_of_year.to_date,
        },
      }
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    private def report_scope
      report_source.viewable_by(current_user)
    end

    private def ignore_mini_profiler
      params[:pp] = 'disabled' # disable rack-mini-profiler
    end
  end
end
