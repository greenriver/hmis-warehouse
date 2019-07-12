###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class RrhController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include PjaxModalController

    before_action :available_projects
    before_action :set_months
    before_action :set_filter
    before_action :set_report
    before_action :set_modal_size

    respond_to :html, :js

    def index

    end

    def clients
      @clients = @report.support_for(params[:metric]&.to_sym, params)
      render layout: 'pjax_modal_content'
    end

    private def set_modal_size
      @modal_size = :xl
    end

    private def set_months
      start_date = ::Reporting::Housed.rrh.minimum(:search_start)
      end_date = ::Reporting::Housed.rrh.maximum(:housing_exit)
      @start_months = (start_date.to_date..end_date.to_date).map do |m|
        [m.strftime('%b %Y'), m.beginning_of_month]
      end.uniq.reverse.drop(1).to_h
      @end_months = (start_date.to_date..end_date.to_date).map do |m|
        [m.strftime('%b %Y'), m.end_of_month]
      end.uniq.reverse.to_h
    end

    private def set_report
      @report = WarehouseReport::RrhReport.new(
        project_ids: @filter.project_ids,
        start_date: @filter.start_date,
        end_date: @filter.end_date,
        subpopulation: @filter.subpopulation,
        household_type: @filter.household_type,
        race: @filter.race,
        ethnicity: @filter.ethnicity,
        gender: @filter.gender,
        veteran_status: @filter.veteran_status,
      )
    end

    private def set_filter
      @filter = OpenStruct.new()
      @filter.start_date = report_params[:start_date]&.to_date rescue @start_months.values[5]
      @filter.end_date = report_params[:end_date]&.to_date rescue @end_months.values[0]
      # force at least a 2 month coverage
      if @filter.start_date > @filter.end_date - 1.months
        @filter.start_date = (@filter.end_date - 1.months).beginning_of_month
      end
      @filter.subpopulation = report_params[:subpopulation]&.to_sym&.presence || :all rescue :all
      @filter.household_type = report_params[:household_type]&.to_sym&.presence || :all rescue :all
      @filter.race = report_params[:race]&.to_sym&.presence || :all rescue :all
      @filter.ethnicity = report_params[:ethnicity]&.to_sym&.presence || :all rescue :all
      @filter.gender = report_params[:gender]&.to_sym&.presence || :all rescue :all
      @filter.veteran_status = report_params[:veteran_status]&.to_sym&.presence || :all rescue :all
      p_ids = report_params[:project_ids].select(&:present?).map(&:to_i) rescue nil
      @filter.project_ids = project_ids(p_ids)
    end

    private def report_params
      params.require(:filter).permit(
        :start_date,
        :end_date,
        :subpopulation,
        :household_type,
        :race,
        :ethnicity,
        :gender,
        :veteran_status,
        project_ids: [],
      )
    end

    private def project_ids project_ids
      return :all unless project_ids.present?
      project_ids = available_projects.map(&:last).
        select{|m| project_ids.include?(m)}
      return project_ids.map(&:to_i) if project_ids
      :all
    end

    private def available_projects
      @available_projects ||= project_source.with_project_type(13).
        joins(:organization).
        pluck(o_t[:OrganizationName].to_sql, :ProjectName, :id).
        map do |org_name, project_name, id|
          ["#{project_name} >> #{org_name}", id]
        end
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

  end
end
