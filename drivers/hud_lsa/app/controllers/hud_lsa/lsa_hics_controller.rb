###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudLsa
  class LsaHicsController < LsasController
    include AjaxModalRails::Controller
    include ArelHelper

    private def report_scope
      report_source.hic.where(report_name: possible_titles)
    end

    # Last Wednesday of January
    private def default_on_date
      Date.new(default_year - 1, 1, 1).last_weekday - 2.days
    end

    def report_version_urls
      super.map { |k, v| [k.sub('LSA', 'HIC'), v] }
    end

    private def filter
      # Some sane defaults, using the previous report if available
      @filter = filter_class.new(
        user_id: current_user.id,
        enforce_one_year_range: false,
      )
      if filter_params.blank?
        prior_report = generator.find_hic_report(current_user)
        options = prior_report&.options
        if options.present?
          @filter.update(options.with_indifferent_access.except(:start, :end))
          @filter.start = nil
          @filter.end = nil
          @filter.on = options['on'].presence || default_on_date
          @filter.coc_code = options['coc_code'].presence || site_coc_codes
          @filter.report_version = options['report_version'].presence || default_report_version
        else
          @filter.start = nil
          @filter.end = nil
          @filter.on = default_on_date
          @filter.report_version = default_report_version
        end
      end
      # Override with params if set
      @filter.update(filter_params) if filter_params.present?
    end

    def filter_params
      filter_p = super
      return {} unless filter_p.present?

      # coc codes acts oddly here
      filter_p[:coc_code] = params[:filter].try(:[], :coc_codes).presence
      filter_p
    end

    def available_report_versions
      {
        'FY 2023' => { slug: :fy2023, active: false },
        'FY 2024' => { slug: :fy2024, active: true },
      }.freeze
    end
    helper_method :available_report_versions

    def default_report_version
      :fy2024
    end

    private def filter_class
      ::HudLsa::Filters::LsaFilter
    end

    private def possible_generator_classes
      {
        fy2023: HudLsa::Generators::Fy2023::Lsa,
        fy2024: HudLsa::Generators::Fy2024::Lsa,
      }
    end

    private def report
      @report ||= report_class.new(options: { user_id: current_user.id, start: default_on_date, end: default_on_date, on: default_on_date })
    end

    private def path_for_report(*options)
      hud_reports_lsa_hic_path(options)
    end

    private def path_for_question_result(_options, report: nil)
      hud_reports_lsa_hic_path(report)
    end

    private def path_for_running_all_questions
      running_all_questions_hud_reports_lsa_hics_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_running_question
      running_hud_reports_lsa_hics_path({ skip_trackable: true }.merge(link_params.except('action', 'controller')))
    end

    private def path_for_history(args = nil)
      history_hud_reports_lsa_hics_path(args)
    end
    helper_method :path_for_history

    private def path_for_new
      new_hud_reports_lsa_hic_path
    end
    helper_method :path_for_new
  end
end
