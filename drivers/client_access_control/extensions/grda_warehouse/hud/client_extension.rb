###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientAccessControl::GrdaWarehouse::Hud
  module ClientExtension
    extend ActiveSupport::Concern
    include ArelHelper

    included do
      # hide previous declaration of :destination_visible_to, we'll use this one
      replace_scope :destination_visible_to, ->(user, source_client_ids: nil) do
        limited_scope = if user.system_user?
          current_scope || all
        else
          arbiter(user).clients_destination_visible_to(user, source_client_ids: source_client_ids)
        end
        merge(limited_scope)
      end

      # hide previous declaration of :source_visible_to, we'll use this one
      replace_scope :source_visible_to, ->(user, client_ids: nil) do
        limited_scope = if user.system_user?
          current_scope || all
        else
          arbiter(user).clients_source_visible_to(user, client_ids: client_ids)
        end
        merge(limited_scope)
      end

      # hide previous declaration of :searchable_to, we'll use this one
      # can search even if no ROI
      replace_scope :searchable_to, ->(user, client_ids: nil) do
        # TODO: START_ACL cleanup after ACL migration is complete
        limited_scope = if user.using_acls?
          arbiter(user).clients_source_searchable_to(user, client_ids: client_ids)
        else
          if user.can_search_all_clients? || user.system_user? # rubocop:disable Style/IfInsideElse
            current_scope || all
          else
            arbiter(user).clients_source_searchable_to(user, client_ids: client_ids)
          end
        end
        # END_ACL
        limited_scope = limited_scope.where(id: client_ids) if client_ids.present?
        merge(limited_scope)
      end

      scope :destination_from_searchable_to, ->(user) do
        destination.where(id: searchable_to(user).
          joins(:warehouse_client_source).
          select(:destination_id))
      end

      def self.arbiter(user)
        # GrdaWarehouse::Config.arbiter_class.new
        user.client_access_arbiter ||= GrdaWarehouse::Config.arbiter_class.new
      end

      # LEGACY Scopes
      scope :searchable_by, ->(user, client_ids: nil) do
        searchable_to(user, client_ids: client_ids)
      end

      scope :viewable_by, ->(user) do
        source_visible_to(user)
      end
      # End LEGACY Scopes

      # Instance Methods
      def show_demographics_to?(user)
        # START_ACLS cleanup after ACL migration is complete
        if user.using_acls?
          return false unless user.can_view_clients? || user.can_view_client_enrollments_with_roi?
        else
          return false unless user.can_view_clients?
        end

        visible_because_of_permission?(user) || visible_because_of_relationship?(user)
      end

      private def visible_because_of_permission?(user)
        # TODO: START_ACL cleanup after ACL migration is complete
        visible = false
        visible ||= visible_because_of_window?(user) unless user.using_acls?
        visible ||= visible_because_of_release?(user)
        visible ||= visible_because_of_data_assignment?(user)
        visible
        # END_ACL
      end

      # TODO: START_ACL remove after ACL migration is complete
      private def visible_because_of_window?(user)
        # defer this to release if required
        return false if GrdaWarehouse::Config.get(:window_access_requires_release)
        return false unless user.can_view_clients?

        (source_clients.distinct.pluck(:data_source_id) & GrdaWarehouse::DataSource.visible_in_window.pluck(:id)).any?
      end
      # END_ACL

      # Check all project ids visible to the user
      private def visible_because_of_data_assignment?(user)
        return false unless user.can_view_clients?

        # TODO: START_ACL cleanup after ACL migration is complete
        if user.using_acls?
          (source_enrollments.joins(:project).pluck(p_t[:id]) & user.viewable_project_ids(:can_view_clients).to_a).present?
        else
          visible_because_of_enrollments = (source_enrollments.joins(:project).pluck(p_t[:id]) & GrdaWarehouse::Hud::Project.viewable_by(user, confidential_scope_limiter: :all, permission: :can_view_clients).pluck(:id)).present?
          visible_because_of_data_sources = (source_clients.pluck(:data_source_id) & user.data_sources.pluck(:id)).present?

          visible_because_of_enrollments || visible_because_of_data_sources
        end
        # END_ACL
      end

      def active_confirmed_consent_in_cocs?(coc_codes)
        consent_form_valid? && valid_in_coc(coc_codes)
      end

      # whether a release is valid in any of the provided CoC codes
      private def valid_in_coc(coc_codes)
        valid_in_any_coc = consented_coc_codes == [] || consented_coc_codes.include?('All CoCs')
        user_client_coc_codes_match = (consented_coc_codes & coc_codes).present?
        valid_in_any_coc || user_client_coc_codes_match
      end

      private def visible_because_of_release?(user)
        # TODO: START_ACL cleanup after ACL migration is complete
        if user.using_acls?
          return false unless user.can_view_client_enrollments_with_roi?
          return false unless consent_form_valid?
        else
          return false unless user.can_view_clients?
          # access isn't governed by release if a client can only search their assigned clients
          return false if user.can_search_own_clients? && ! (user.can_use_strict_search? || user.can_search_window? || user.can_search_all_clients?)
          return unless consent_form_valid?
        end
        # END_ACL

        valid_in_coc(user.coc_codes)
      end

      private def visible_because_of_relationship?(user)
        user_clients.pluck(:user_id).include?(user.id) && consent_form_valid? && user.can_search_own_clients?
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

      # build an array of useful hashes for the enrollments roll-ups
      private def enrollments_for(en_scope, user:, include_confidential_names: false)
        Rails.cache.fetch("clients/#{id}/enrollments_for/#{en_scope.to_sql}/#{include_confidential_names}/#{user.id}", expires_in: ::GrdaWarehouse::Hud::Client::CACHE_EXPIRY) do
          total_enrollment_count = en_scope.joins(:project, :source_client, :enrollment).count
          en_scope = en_scope.joins(:enrollment).merge(::GrdaWarehouse::Hud::Enrollment.visible_to(user)) unless user == User.setup_system_user
          enrollments = en_scope.joins(:project, :source_client, :enrollment).
            includes(:organization, :source_client, project: :project_cocs, enrollment: [:enrollment_cocs, :exit, :ch_enrollment]).
            order(first_date_in_program: :desc)
          visible_enrollment_count = enrollments.count
          enrollments.map do |entry|
            project = entry.project
            organization = entry.organization
            dates_served = entry.service_history_services.where(record_type: service_types).distinct.pluck(:date)
            project_name = if project.confidential? && ! include_confidential_names
              project.safe_project_name
            else
              cocs = ''
              if ::GrdaWarehouse::Config.get(:expose_coc_code)
                cocs = project.project_cocs&.pluck(GrdaWarehouse::Hud::ProjectCoc.coc_code_coalesce)&.reject(&:blank?)&.uniq&.join(', ')
                cocs = " (#{cocs})" if cocs.present?
              end
              "#{entry.project_name} < #{organization.OrganizationName} #{cocs}"
            end
            count_until = calculated_end_of_enrollment(enrollment: entry, enrollments: enrollments)
            # days included in adjusted days that are not also served by a residential project
            adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
            homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: enrollments)
            # extrapolated days may extend beyond the actual last contact, turning off ineligible_uses_extrapolated_days means
            # we only count actual contacts
            most_recent_service = if GrdaWarehouse::Config.get(:ineligible_uses_extrapolated_days)
              dates_served.max
            else
              entry.service_history_services.service_excluding_extrapolated.maximum(:date)
            end
            new_episode = new_episode?(enrollments: enrollments, enrollment: entry)
            {
              client_source_id: entry.source_client.id,
              project_id: project.id,
              ProjectID: project.ProjectID,
              project_name: project_name,
              confidential_project: project.confidential,
              entry_date: entry.first_date_in_program,
              living_situation: entry.enrollment.LivingSituation,
              chronically_homeless_at_start: entry.enrollment.chronically_homeless_at_start?,
              exit_date: entry.last_date_in_program,
              destination: entry.destination,
              move_in_date_inherited: entry.enrollment.MoveInDate.blank? && entry.move_in_date.present?,
              move_in_date: entry.move_in_date,
              days: dates_served.count,
              homeless: entry.computed_project_type.in?(::HudUtility2024.homeless_project_types),
              residential: entry.computed_project_type.in?(::HudUtility2024.residential_project_type_ids),
              homeless_days: homeless_dates_for_enrollment.count,
              adjusted_days: adjusted_dates_for_similar_programs.count,
              months_served: adjusted_months_served(dates: adjusted_dates_for_similar_programs),
              household: household(entry.household_id, entry.enrollment.data_source_id),
              project_type: ::HudUtility2024.project_type_brief(entry.computed_project_type),
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
              total_enrollment_count: total_enrollment_count,
              visible_enrollment_count: visible_enrollment_count,
              # support: dates_served,
            }
          end
        end
      end

      def enrollments_for_verified_homeless_history(user: nil)
        scope = service_history_enrollments

        case ::GrdaWarehouse::Config.get(:verified_homeless_history_method).to_sym
        when :all_enrollments
          scope
        when :visible_in_window
          scope.joins(:data_source).merge(::GrdaWarehouse::DataSource.where(visible_in_window: true))
        when :visible_to_user
          raise 'User is missing' unless user.present?

          scope.visible_in_window_to(user)
        when :release
          raise 'User is missing' unless user.present?

          if release_valid?(coc_codes: user.coc_codes)
            scope
          else
            scope.visible_in_window_to(user)
          end
        else
          raise NotImplementedError
        end
      end
    end
  end
end
