###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      scope :destination_visible_to, ->(user) do
        current_scope ||= destination
        GrdaWarehouse::Config.arbiter_class.new.clients_destination_visible_to(current_scope, user)
      end

      scope :source_visible_to, ->(user) do
        GrdaWarehouse::Config.arbiter_class.new.clients_source_visible_to(current_scope, user)
      end

      # can search even if no ROI
      scope :searchable_to, ->(user) do
        current_scope ||= source
        return current_scope if user.can_search_all_clients?

        GrdaWarehouse::Config.arbiter_class.new.clients_source_visible_to(current_scope, user)
      end

      # LEGACY Scopes
      def self.exists_with_inner_clients(inner_scope)
        inner_scope = inner_scope.to_sql.gsub('"Client".', '"inner_clients".').gsub('"Client"', '"Client" as "inner_clients"')
        Arel.sql("EXISTS (#{inner_scope} and \"Client\".\"id\" = \"inner_clients\".\"id\")")
      end

      scope :searchable_by, ->(user) do
        searchable_to(user)
      end

      scope :viewable_by, ->(user) do
        project_query = exists_with_inner_clients(visible_by_project_to(user))
        window_query = exists_with_inner_clients(visible_in_window_to(user))
        active_consent_query = if GrdaWarehouse::Config.get(:multi_coc_installation)
          exists_with_inner_clients(active_confirmed_consent_in_cocs(user.coc_codes))
        else
          exists_with_inner_clients(consent_form_valid)
        end
        if user.can_view_clients_with_roi_in_own_coc?
          # At a high level if you can see clients with ROI in your COC, you need to be able
          # to see everyone for searching purposes.
          # limits will be imposed on accessing the actual client dashboard pages
          # current_scope

          # If the user has coc-codes specified, this will limit to users
          # with a valid consent form in the coc or with no-coc specified
          # If the user does not have a coc-code specified, only clients with a full (CoC not specified) release
          # are included.
          if user&.can_see_clients_in_window_for_assigned_data_sources?
            ds_ids = user.data_sources.pluck(:id)
            sql = arel_table[:data_source_id].in(ds_ids).
              or(active_consent_query).
              or(project_query)
            sql = sql.or(window_query) unless GrdaWarehouse::Config.get(:window_access_requires_release)
            where(sql)
          else
            active_confirmed_consent_in_cocs(user.coc_codes)
          end
        elsif user.can_view_clients? || user.can_edit_clients?
          current_scope
        else
          ds_ids = user.data_sources.pluck(:id)
          sql = if user&.can_see_clients_in_window_for_assigned_data_sources? && ds_ids.present?
            arel_table[:data_source_id].in(ds_ids)
          else
            arel_table[:id].eq(0) # no client should have a 0 id
          end
          sql = sql.or(project_query)
          if GrdaWarehouse::Config.get(:window_access_requires_release)
            sql = sql.or(active_consent_query)
          else
            sql = sql.or(window_query)
          end
          where(sql)
        end
      end

      # accepts either a destination or source client id, determines if the destination client is visible
      def self.destination_client_viewable_by_user(client_id:, user:)
        destination.where(
          Arel.sql(
            arel_table[:id].in(visible_by_source(id: client_id, user: user)).
            or(arel_table[:id].in(visible_by_destination(id: client_id, user: user))).to_sql,
          ),
        )
      end

      def self.visible_by_source(id:, user:)
        query = GrdaWarehouse::WarehouseClient.joins(:source).merge(viewable_by(user))
        query = query.where(destination_id: id) if id.present?
        Arel.sql(query.select(:destination_id).to_sql)
      end

      def self.visible_by_destination(id:, user:)
        query = viewable_by(user)
        query = query.where(id: id) if id.present?
        Arel.sql(query.select(:id).to_sql)
      end

      scope :visible_in_window_to, ->(user) do
        joins(:data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(user))
      end

      scope :visible_by_project_to, ->(user) do
        joins(enrollments: :project).merge(GrdaWarehouse::Hud::Project.viewable_by(user))
      end

      # Instance Methods
      def show_demographics_to?(user)
        visible_because_of_permission?(user) || visible_because_of_relationship?(user)
      end

      def visible_because_of_permission?(user)
        user.can_view_clients? ||
        visible_because_of_release?(user) ||
        visible_because_of_assigned_data_source?(user) ||
        visible_because_of_coc_association?(user)
      end

      def visible_because_of_release?(user)
        any_window_clients = source_clients.map { |sc| sc.data_source&.visible_in_window? }.any?
        # user can see the window, and client has a valid release, or none is required (by the site config)
        user.can_view_client_window? &&
        (
          release_valid? ||
          ! GrdaWarehouse::Config.get(:window_access_requires_release) && any_window_clients
        )
      end

      # This permission is mis-named a bit, it should check all project ids visible to the user
      def visible_because_of_assigned_data_source?(user)
        return false unless user.can_see_clients_in_window_for_assigned_data_sources?

        visible_because_of_enrollments = (source_enrollments.joins(:project).pluck(p_t[:id]) & GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id)).present?
        visible_because_of_data_sources = (source_clients.pluck(:data_source_id) & user.data_sources.pluck(:id)).present?

        visible_because_of_enrollments || visible_because_of_data_sources
      end

      def visible_because_of_coc_association?(user)
        user.can_view_clients_with_roi_in_own_coc? &&
        release_valid? &&
        (
          consented_coc_codes == [] ||
          (consented_coc_codes & user.coc_codes).present?
        )
      end

      def visible_because_of_relationship?(user)
        user_clients.pluck(:user_id).include?(user.id) && release_valid? && user.can_search_window?
      end
      # Define a bunch of disability methods we can use to get the response needed
      # for CAS integration
      # This generates methods like: substance_response()
      GrdaWarehouse::Hud::Disability.disability_types.each_value do |disability_type|
        define_method "#{disability_type}_response".to_sym do
          disability_check = "#{disability_type}?".to_sym
          source_disabilities.response_present.
            newest_first.
            detect(&disability_check).try(:response)
        end
      end

      GrdaWarehouse::Hud::Disability.disability_types.each_value do |disability_type|
        define_method "#{disability_type}_response?".to_sym do
          send("#{disability_type}_response".to_sym) == 'Yes'
        end
      end

      # build an array of useful hashes for the enrollments roll-ups
      def enrollments_for(en_scope, user:, include_confidential_names: false)
        Rails.cache.fetch("clients/#{id}/enrollments_for/#{en_scope.to_sql}/#{include_confidential_names}/#{user.id}", expires_in: ::GrdaWarehouse::Hud::Client::CACHE_EXPIRY) do
          en_scope = en_scope.joins(:enrollment).merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)) unless user == User.setup_system_user
          enrollments = en_scope.joins(:project, :source_client, :enrollment).
            includes(:service_history_services, :project, :organization, :source_client, enrollment: [:enrollment_cocs, :exit]).
            order(first_date_in_program: :desc)
          enrollments.map do |entry|
            project = entry.project
            organization = entry.organization
            services = entry.service_history_services
            project_name = if project.confidential? && ! include_confidential_names
              project.safe_project_name
            else
              cocs = ''
              if ::GrdaWarehouse::Config.get(:expose_coc_code)
                cocs = entry.enrollment&.enrollment_cocs&.map(&:CoCCode)&.uniq&.join(', ')
                cocs = " (#{cocs})" if cocs.present?
              end
              "#{entry.project_name} < #{organization.OrganizationName} #{cocs}"
            end
            dates_served = services.select { |m| service_types.include?(m.record_type) }.map(&:date).uniq
            count_until = calculated_end_of_enrollment(enrollment: entry, enrollments: enrollments)
            # days included in adjusted days that are not also served by a residential project
            adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
            homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: enrollments)
            most_recent_service = services.sort_by(&:date)&.last&.date
            new_episode = new_episode?(enrollments: enrollments, enrollment: entry)
            {
              client_source_id: entry.source_client.id,
              project_id: project.id,
              ProjectID: project.ProjectID,
              project_name: project_name,
              confidential_project: project.confidential,
              entry_date: entry.first_date_in_program,
              living_situation: entry.enrollment.LivingSituation,
              exit_date: entry.last_date_in_program,
              destination: entry.destination,
              move_in_date_inherited: entry.enrollment.MoveInDate.blank? && entry.move_in_date.present?,
              move_in_date: entry.move_in_date,
              days: dates_served.count,
              homeless: entry.computed_project_type.in?(::GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES),
              homeless_days: homeless_dates_for_enrollment.count,
              adjusted_days: adjusted_dates_for_similar_programs.count,
              months_served: adjusted_months_served(dates: adjusted_dates_for_similar_programs),
              household: household(entry.household_id, entry.enrollment.data_source_id),
              project_type: ::HUD.project_type_brief(entry.computed_project_type),
              project_type_id: entry.computed_project_type,
              class: "client__service_type_#{entry.computed_project_type}",
              most_recent_service: most_recent_service,
              new_episode: new_episode,
              enrollment_id: entry.enrollment.EnrollmentID,
              data_source_id: entry.enrollment.data_source_id,
              created_at: entry.enrollment.DateCreated,
              updated_at: entry.enrollment.DateUpdated,
              hmis_id: entry.enrollment.id,
              hmis_exit_id: entry.enrollment&.exit&.id,
              # support: dates_served,
            }
          end
        end
      end

      def enrollments_for_rollup(user:, en_scope: scope, include_confidential_names: false, only_ongoing: false)
        Rails.cache.fetch("clients/#{id}/enrollments_for_rollup/#{en_scope.to_sql}/#{include_confidential_names}/#{only_ongoing}/#{user.id}", expires_in: ::GrdaWarehouse::Hud::Client::CACHE_EXPIRY) do
          if en_scope.count.zero?
            []
          else
            enrollments = enrollments_for(en_scope, include_confidential_names: include_confidential_names, user: user)
            enrollments = enrollments.select { |m| m[:exit_date].blank? } if only_ongoing
            enrollments || []
          end
        end
      end
    end
  end
end
