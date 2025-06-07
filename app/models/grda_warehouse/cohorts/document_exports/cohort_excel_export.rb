# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'axlsx_rails/template_handler'

module GrdaWarehouse::Cohorts::DocumentExports
  # Handles export of cohort data to Excel files (.xlsx) format
  #
  # This class is responsible for:
  # - Validating user authorization for cohort downloads
  # - Collecting cohort data based on specified population parameters
  # - Rendering an Excel workbook using the axlsx template engine
  # - Creating a downloadable file with proper naming and MIME type
  class CohortExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_download_cohorts?
    end

    protected def cohort
      @cohort ||= cohort_class.viewable_by(user).find(params['id'])
    end

    protected def cohort_clients
      cohort.search_clients(population: population, user: user)
    end

    protected def population
      params['population'] ||= 'Active Clients'
    end

    protected def cohort_names
      @cohort_names ||= cohort_class.pluck(:id, :name, :short_name).
        map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end

    protected def view_assigns
      {
        user: user,
        cohort: cohort,
        cohort_clients: cohort_clients,
        population: population,
        cohort_names: cohort_names,
      }
    end

    def perform
      with_status_progression do
        preflight_checks

        ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
        warden_proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
          i.set_user(user, scope: :user, store: false, run_callbacks: false)
        end

        renderer = controller_class.renderer.new(
          'warden' => warden_proxy,
        )

        write_tmp_file(
          renderer.render(
            template: 'cohorts/export',
            formats: [:xlsx],
            handlers: [:axlsx], # Forces Rails to use the Axlsx handler
            assigns: view_assigns,
          ),
          "Cohort - #{cohort.name} - #{params['population']} - #{Time.current.to_fs(:db)}",
        ) do |io|
          self.downloadable_file = io
        end
      end
    end

    def downloadable_file=(file_io)
      self.filename = File.basename(file_io.path)
      self.file_data = file_io.read
      self.mime_type = EXCEL_MIME_TYPE
    end

    # additional instrumentation that we should take out in the future once we resolve #7751
    private def preflight_checks
      expected_handler_class = AxlsxRails::TemplateHandler
      current_handler_class = ActionView::Template.handler_for_extension('axlsx')

      # Check if the correct handler class is registered.
      return if current_handler_class == expected_handler_class

      # If not, log the unexpected handler and attempt to re-register the correct class.
      Sentry.capture_message(
        "axlsx handler was a #{current_handler_class.class.name}, expected #{expected_handler_class.name} class. Attempting to re-register.",
      )
      ActionView::Template.register_template_handler(:axlsx, expected_handler_class.new)

      Rails.logger.info "Job Renderer ActionView template handlers: #{ActionView::Template.template_handler_extensions.inspect}"

      true
    end

    private def write_tmp_file(data, file_name)
      Dir.mktmpdir do |dir|
        safe_name = file_name.gsub(/[^- a-z0-9]+/i, ' ').slice(0, 50).strip
        file_path = "#{dir}/#{safe_name}.xlsx"
        File.open(file_path, 'wb') { |file| file.write(data) }
        yield(Pathname.new(file_path).open)
      end
      true
    end

    protected def cohort_class
      GrdaWarehouse::Cohort
    end

    def generator_url
      cohort_path(cohort)
    end

    private def controller_class
      CohortsController
    end
  end
end
