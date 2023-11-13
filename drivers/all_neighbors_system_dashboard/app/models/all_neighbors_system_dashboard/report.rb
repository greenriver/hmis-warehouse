###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Some semi-useful testing notes:
# reload!; @report = AllNeighborsSystemDashboard::Report.find(244); @report.delete_cached_values!; AllNeighborsSystemDashboard::HousingTotalPlacementsData.cache_data(@report)
module AllNeighborsSystemDashboard
  class Report < SimpleReports::ReportInstance
    include Rails.application.routes.url_helpers
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status

    include ViewConfiguration
    include EnrollmentAttributeCalculations

    include ::WarehouseReports::Publish

    has_one_attached :result_file
    has_many :datasets, class_name: '::GrdaWarehouse::Dataset', as: :source
    has_many :published_reports, dependent: :destroy, class_name: '::GrdaWarehouse::PublishedReport'

    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def delete_cached_values!
      datasets.delete_all
    end

    def cache_key
      [
        self.class.name,
        id,
      ].join('/')
    end

    def run_and_save!
      start
      begin
        populate_universe
      rescue Exception => e
        update(failed_at: Time.current)
        raise e
      end
      cache_calculated_data
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def url
      all_neighbors_system_dashboard_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: :https, format: :xlsx)
    end

    def a_t
      @a_t ||= Enrollment.arel_table
    end

    def cache_calculated_data
      AllNeighborsSystemDashboard::Header.cache_data(self)
      AllNeighborsSystemDashboard::HousingTotalPlacementsData.cache_data(self)
      AllNeighborsSystemDashboard::ReturnsToHomelessness.cache_data(self)
      AllNeighborsSystemDashboard::TimeToObtainHousing.cache_data(self)
      AllNeighborsSystemDashboard::UnhousedPopulation.cache_data(self)
    end

    def populate_universe
      enrollment_scope.preload(
        :enrollment,
        :client,
        :project,
        :service_history_enrollment_for_head_of_household,
      ).find_in_batches do |batch|
        enrollments = {}
        ce_infos = ce_infos_for_batch(filter, batch)
        return_dates = return_dates_for_batch(filter, batch)
        batch.each do |enrollment|
          source_enrollment = enrollment.enrollment
          hoh_enrollment = enrollment.service_history_enrollment_for_head_of_household&.enrollment || source_enrollment
          ce_info = ce_infos[enrollment.id]
          # Latest CE Event that occurred on or before enrollment.entry_date
          # this would be the referral to housing (or the identification that someone needed housing)
          max_event = ce_info&.ce_event&.select { |e| e.event_date <= enrollment.entry_date }&.max_by(&:event_date)
          # inherit move_in_date from hoh enrollment
          move_in_date = enrollment.move_in_date || hoh_enrollment.move_in_date
          # invalidate move_in_date if it's after the report end_date
          move_in_date = nil if move_in_date.present? && move_in_date > filter.end_date

          enrollments[enrollment.id] = Enrollment.new(
            report_id: id,
            destination_client_id: enrollment.client_id,
            household_id: enrollment.household_id,
            household_type: household_type(enrollment),
            prior_living_situation_category: prior_living_situation_category(hoh_enrollment),
            enrollment_id: source_enrollment.enrollment_id,
            entry_date: enrollment.first_date_in_program,
            move_in_date: move_in_date,
            exit_date: exit_date(filter, enrollment),
            adjusted_exit_date: adjusted_exit_date(filter, enrollment),
            exit_type: exit_type(filter, enrollment),
            destination: enrollment.destination,
            destination_text: HudUtility2024.destination(enrollment.destination),
            relationship: relationship(source_enrollment),
            relationship_to_hoh: source_enrollment.relationship_to_hoh,
            personal_id: source_enrollment.personal_id,
            age: enrollment.age,
            gender: gender(enrollment),
            primary_race: primary_race(enrollment),
            race_list: enrollment.client.race_description(include_missing_reason: true),
            # ethnicity: HudUtility2024.ethnicity(enrollment.client.ethnicity),
            ce_entry_date: ce_info&.entry_date,
            ce_referral_date: max_event&.event_date,
            ce_referral_id: max_event&.event_id,
            return_date: return_dates[enrollment.id],
            project_id: enrollment.project.id,
            project_name: enrollment.project.name, # get from project directly to handle project confidentiality
            project_type: enrollment.project_type,
          )
        end
        Enrollment.import!(enrollments.values)
        universe.add_universe_members(enrollments)
      end

      # Attach the CE Events to the first report enrollment (requires at least one enrollment)
      enrollment = universe.members.first.universe_membership
      return unless enrollment.present?

      event_scope.find_in_batches do |batch|
        events = []
        batch.each do |event|
          events << enrollment.events.build(
            personal_id: event.personal_id,
            source_enrollment_id: event.enrollment_id,
            event_id: event.event_id,
            event_date: event.event_date,
            event: HudUtility2024.event(event.event),
            location: event.location_crisis_or_ph_housing,
            project_name: event.enrollment.project.name,
            project_type: event.enrollment.project.project_type,
            referral_result: event.referral_result,
            result_date: event.result_date,
          )
        end
        Event.import!(events)
      end
    end

    # NOTE: this report has two implementation phases
    # pre 5/1/2023 it was the DRTRR which is represented by filter.effective_project_ids_from_secondary_project_groups (we'll call this the pilot period)
    # 5/1/2023 onward is represented by filter.effective_project_ids (we'll call this the implementation period)
    def enrollment_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:enrollment, :client).
        entry.
        open_between(start_date: filter.start_date, end_date: filter.end_date).
        in_project(GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids + filter.secondary_project_ids))
    end

    def event_scope
      GrdaWarehouse::Hud::Event.
        joins(enrollment: :project).
        preload(enrollment: :project).
        within_range(filter.range).
        where(Event: SERVICE_CODE_IDS)
    end

    # Publishing
    def publish_files
      [
        {
          name: 'index.html',
          content: -> { as_html },
          type: 'text/html',
        },
        {
          name: 'application.css',
          content: -> {
            css = Rails.application.assets['application.css'].to_s
            # need to replace the paths to the font files
            [
              'icons.ttf',
              'icons.svg',
              'icons.eot',
              'icons.woff',
              'icons.woff2',
            ].each do |filename|
              css.gsub!("url(/assets/#{Rails.application.assets[filename].digest_path}", "url(#{filename}")
            end
            css
          },
          type: 'text/css',
        },
        {
          name: 'icons.ttf',
          content: -> { Rails.application.assets['icons.ttf'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.svg',
          content: -> { Rails.application.assets['icons.svg'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.eot',
          content: -> { Rails.application.assets['icons.eot'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.woff',
          content: -> { Rails.application.assets['icons.woff'].to_s },
          type: 'text/css',
        },
        {
          name: 'icons.woff2',
          content: -> { Rails.application.assets['icons.woff'].to_s },
          type: 'text/css',
        },
        {
          name: 'bar.js',
          content: -> { File.read(asset_path('bar.js.es6')) },
          type: 'text/javascript',
        },
        {
          name: 'donut.js',
          content: -> { File.read(asset_path('donut.js.es6')) },
          type: 'text/javascript',
        },
        {
          name: 'filters.js',
          content: -> { File.read(asset_path('filters.js.es6')) },
          type: 'text/javascript',
        },
        {
          name: 'line.js',
          content: -> { File.read(asset_path('line.js.es6')) },
          type: 'text/javascript',
        },
        {
          name: 'stack.js',
          content: -> { File.read(asset_path('stack.js.es6')) },
          type: 'text/javascript',
        },
      ]
    end

    # Override the default to remove the sandbox attribute
    private def generate_embed_code
      "<iframe width='800' height='1200' src='#{generate_publish_url}' frameborder='0'><a href='#{generate_publish_url}'>#{instance_title}</a></iframe>"
    end

    private def asset_path(asset)
      Rails.root.join('app', 'assets', 'javascripts', 'warehouse_reports', 'all_neighbors_system_dashboard', asset)
    end
  end
end
