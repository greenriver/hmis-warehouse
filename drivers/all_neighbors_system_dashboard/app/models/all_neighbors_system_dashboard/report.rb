###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

    PILOT_END_DATE = '2023-05-01'.to_date.freeze

    has_one_attached :result_file
    has_many :datasets, class_name: '::GrdaWarehouse::Dataset', as: :source
    has_many :published_reports, dependent: :destroy, class_name: '::GrdaWarehouse::PublishedReport'
    has_many :enrollments

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
        deduplicate_universe!
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
      all_neighbors_system_dashboard_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: :https)
    end

    def a_t
      @a_t ||= Enrollment.arel_table
    end

    def cache_calculated_data
      AllNeighborsSystemDashboard::Header.cache_data(self)
      AllNeighborsSystemDashboard::HousingTotalPlacementsData.cache_data(self)
      AllNeighborsSystemDashboard::TimeToObtainHousing.cache_data(self)
      AllNeighborsSystemDashboard::ReturnsToHomelessness.cache_data(self)
      # Disabled until these tabs come back to speed up report runtime
      # AllNeighborsSystemDashboard::UnhousedPopulation.cache_data(self)
    end

    def populate_universe
      enrollment_scope.preload(
        :enrollment,
        :client,
        :project,
        client_head_of_household: :warehouse_client_source,
      ).find_in_batches do |batch|
        report_enrollments = {}
        ce_infos = ce_infos_for_batch(filter, batch)
        return_dates = return_dates_for_batch(filter, batch)
        pilot_project_ids = filter.effective_project_ids_from_secondary_project_groups

        batch.each do |enrollment|
          source_enrollment = enrollment.enrollment
          hoh_enrollment = hoh(source_enrollment)
          ce_info = ce_infos[enrollment.id]
          # Latest CE Event that occurred on or before enrollment.entry_date
          # this would be the referral to housing (or the identification that someone needed housing)
          max_event = ce_info&.ce_event&.select { |e| e.event_date <= enrollment.entry_date }&.max_by(&:event_date)
          # inherit move_in_date from hoh enrollment
          move_in_date = enrollment.move_in_date || hoh_enrollment[:move_in_date]
          # invalidate move_in_date if it's after the report end_date
          move_in_date = nil if move_in_date.present? && move_in_date > filter.end_date

          exit_type = exit_type(filter, enrollment)
          exit_date = exit_date(filter, enrollment)
          diversion_enrollment = enrollment.project.id.in?(filter.secondary_project_ids)

          placed_date = if diversion_enrollment && exit_type == 'Permanent'
            exit_date
          elsif enrollment.project.ph?
            move_in_date
          end
          # Exclude any client who doesn't have a placement
          next unless placed_date.present?

          # Adjust the placed date to be inside the enrolment, pre-entry moves to entry date, post exit, moves to exit date
          placed_date = enrollment.entry_date if placed_date < enrollment.entry_date
          placed_date = exit_date if exit_date.present? && placed_date > exit_date

          # Exclude any records where the placement occurred outside of the report range
          next unless placed_date.in?(filter.range)

          # Only count DRTRR projects for placement dates prior to 5/1/2023
          # For ease of running, we've added the diversion projects to the DRTRR project group, but we'll only include
          # placements that occurred at PH projects prior to 5/1/2023
          next if placed_date < PILOT_END_DATE && (!pilot_project_ids.include?(enrollment.project.id) || !enrollment.project.ph?)

          report_enrollments[enrollment.id] = Enrollment.new(
            report_id: id,
            destination_client_id: enrollment.client_id,
            household_id: enrollment.household_id,
            household_type: household_type(source_enrollment),
            prior_living_situation_category: prior_living_situation_category(hoh_enrollment[:living_situation]),
            enrollment_id: source_enrollment.enrollment_id,
            entry_date: enrollment.first_date_in_program,
            move_in_date: move_in_date,
            exit_date: exit_date,
            placed_date: placed_date,
            adjusted_exit_date: adjusted_exit_date(filter, enrollment),
            exit_type: exit_type,
            destination: enrollment.destination,
            destination_text: HudUtility2024.destination(enrollment.destination),
            relationship: relationship(source_enrollment),
            relationship_to_hoh: source_enrollment.relationship_to_hoh,
            personal_id: source_enrollment.personal_id,
            age: enrollment.age,
            gender: gender(enrollment),
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
        Enrollment.import!(report_enrollments.values)
        universe.add_universe_members(report_enrollments)
      end

      # Attach the CE Events to the first report enrollment (requires at least one enrollment)
      enrollment = universe.members.first&.universe_membership
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

    # Find duplicate enrollments based on date client and date, keeping only one row per client per date in the following priority order:
    #
    # 1. PSH move-in (Project Type 3)
    # 2. PH with services move-in (Project Type 10)
    # 3. PH without services move-in (Project Type 9)
    # 4. RRH move-in (Project Type 13)
    # 5. Diversion
    # 6. Latest exit date
    # 7. Latest entry date
    def deduplicate_universe!
      # NOTE: we aren't using the simple report universe anywhere else, using enrollments is way easier.
      cols = [
        :destination_client_id,
        :project_id,
        :project_type,
        :move_in_date,
        :exit_date,
        :entry_date,
        :id,
      ]
      duplicates = enrollments.
        pluck(*cols).
        group_by do |row|
          row = cols.zip(row).to_h
          date = if row[:project_type].in?(HudUtility2024.project_types_with_move_in_dates)
            row[:move_in_date]
          elsif row[:project_id].in?(filter.secondary_project_ids)
            row[:exit_date]
          end
          [
            row[:destination_client_id],
            date,
          ]
        end.delete_if { |_, dates| dates.uniq.count == 1 }
      priority_project_type_order = [3, 10, 9, 13]
      keep = {}
      all_duplicate_ids = Set.new
      duplicates.each do |_, rows|
        # operating on one client for one day
        rows.each do |row|
          row = cols.zip(row).to_h
          client_id = row[:destination_client_id]
          all_duplicate_ids << row[:id]
          # if we haven't picked one, just add the first
          keep[client_id] ||= row
          next if row[:id] == keep[client_id][:id]

          if row[:project_type] == keep[client_id][:project_type]
            # if we have the same project type, pick the later entry date
            keep[client_id] = row if row[:entry_date] > keep[client_id][:entry_date]

            # if we have the same project type, pick the later exit date, prefer an open enrolment
            if row[:exit_date].blank? && keep[client_id][:exit_date].present?
              keep[client_id] = row
            elsif row[:exit_date].present? && keep[client_id][:exit_date].present? && row[:exit_date] > keep[client_id][:exit_date]
              keep[client_id] = row
            end
          else
            # Sort by project type priority, set any diversion to 100 (max PH will be 3)
            row_project_type_index = priority_project_type_order.index(row[:project_type]) || 100
            keep_project_type_index = priority_project_type_order.index(keep[client_id][:project_type]) || 100
            keep[client_id] = row if row_project_type_index < keep_project_type_index
          end
        end
      end
      return unless keep.any?

      remove_ids = all_duplicate_ids - keep.values.map { |m| m[:id] }
      enrollments.where(id: remove_ids).delete_all
      # Cleanup the universe for good measure
      universe.universe_members.where(universe_membership_id: remove_ids).delete_all
    end

    def enrollment_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:client, :project, enrollment: :client).
        entry.
        open_between(start_date: filter.start_date, end_date: filter.end_date).
        in_project(
          GrdaWarehouse::Hud::Project.
            where(
              # Project is in the report universe OR in a Diversion project (represented by secondary_project_ids)
              id: filter.effective_project_ids + filter.secondary_project_ids,
            ),
        )
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
              css.gsub!("url(#{Rails.application.config.assets.prefix}/#{Rails.application.assets[filename].digest_path}", "url(#{filename}")
              # Also replace development version of assets url
              css.gsub!("url(#{Rails.application.config.assets.prefix}/#{Rails.application.assets[filename].digest_path}", "url(#{filename}")
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
          content: -> { File.read(per_page_js_asset_path('all_neighbors_system_dashboard_bar.js')) },
          type: 'text/javascript',
        },
        {
          name: 'donut.js',
          content: -> { File.read(per_page_js_asset_path('all_neighbors_system_dashboard_donut.js')) },
          type: 'text/javascript',
        },
        {
          name: 'filters.js',
          content: -> { File.read(per_page_js_asset_path('all_neighbors_system_dashboard_filters.js')) },
          type: 'text/javascript',
        },
        {
          name: 'line.js',
          content: -> { File.read(per_page_js_asset_path('all_neighbors_system_dashboard_line.js')) },
          type: 'text/javascript',
        },
        {
          name: 'stack.js',
          content: -> { File.read(per_page_js_asset_path('all_neighbors_system_dashboard_stack.js')) },
          type: 'text/javascript',
        },
      ]
    end

    # Override the default to remove the sandbox attribute
    private def generate_embed_code
      "<iframe width='800' height='1200' src='#{generate_publish_url}' frameborder='0'><a href='#{generate_publish_url}'>#{instance_title}</a></iframe>"
    end

    # This should probably use something like what we do in AssetHelper.inline_js_for_es_build
    private def per_page_js_asset_path(asset)
      return Rails.root.join('app', 'assets', 'builds', asset) if Rails.env.development?

      ext = File.extname(asset)
      asset_name = File.basename(asset, ext)
      asset_path = Rails.root.join('public', 'assets', "#{asset_name}-*#{ext}")
      Dir.glob(asset_path).first
    end
  end
end
