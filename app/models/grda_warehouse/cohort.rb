###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'

module GrdaWarehouse
  class Cohort < GrdaWarehouseBase
    include ArelHelper
    include AccessGroups # TODO: START_ACL remove this after permission migration is complete
    include EntityAccess
    include Memery
    include Rails.application.routes.url_helpers

    acts_as_paranoid
    has_paper_trail

    validates_presence_of :name
    validates :days_of_inactivity, numericality: { only_integer: true, allow_nil: true }
    validates :static_column_count, numericality: { only_integer: true }
    serialize :column_state, Array

    after_create :maintain_system_group

    has_many :cohort_tabs, dependent: :destroy
    has_many :cohort_clients, dependent: :destroy
    has_many :clients, through: :cohort_clients, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :tags, class_name: 'CasAccess::Tag', optional: true
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup', optional: true

    has_many :group_viewable_entities, -> { where(entity_type: 'GrdaWarehouse::Cohort') }, class_name: 'GrdaWarehouse::GroupViewableEntity', foreign_key: :entity_id

    # START_ACL remove this after permission migration is complete
    # NOTE: these are in the app DB
    has_many :access_groups, through: :group_viewable_entities
    # has_many :legacy_users, through: :access_groups
    # END_ACL

    # NOTE: these are in the app DB
    has_many :collections, through: :group_viewable_entities
    has_many :access_controls, through: :collections
    has_many :users, through: :access_controls

    attr_accessor :client_ids, :participant_ids, :viewer_ids, :user_ids # TODO: START_ACL remove :user_ids after permission migration is complete

    scope :active, -> do
      where(active_cohort: true)
    end

    scope :active_user, -> do
      where(active_cohort: true, system_cohort: false)
    end

    scope :inactive, -> do
      where(active_cohort: false, system_cohort: false)
    end

    scope :visible_in_cas, -> do
      where(visible_in_cas: true)
    end

    scope :show_on_client_dashboard, -> do
      where(show_on_client_dashboard: true)
    end

    scope :system_cohorts, -> do
      where(system_cohort: true)
    end

    scope :auto_maintained, -> do
      where.not(project_group_id: nil)
    end

    scope :viewable_by, ->(user) do
      return none unless user.present?

      # TODO: START_ACL cleanup after permission migration is complete
      if user.using_acls?
        return none unless GrdaWarehouse::Cohort.viewable_permissions.map { |perm| user.send("#{perm}?") }.any?

        ids = GrdaWarehouse::Cohort.viewable_permissions.flat_map do |perm|
          group_ids = user.collections_for_permission(perm)
          next [] if group_ids.empty?

          GrdaWarehouse::GroupViewableEntity.where(
            collection_id: group_ids,
            entity_type: 'GrdaWarehouse::Cohort',
          ).pluck(:entity_id)
        end.compact
        return none if ids.empty?

        where(id: ids)
      else
        if user.can_access_some_cohorts # rubocop:disable Style/IfInsideElse
          if current_scope.present?
            current_scope.merge(user.cohorts)
          else
            user.cohorts
          end
        else
          none
        end
      end
      # END_ACL
    end

    scope :editable_by, ->(user) do
      return none unless user.present?
      return none if user.using_acls? && viewable_permissions.map { |perm| user.send("#{perm}?") }.none? # TODO: START_ACL cleanup after permission migration is complete

      # TODO: START_ACL cleanup after permission migration is complete
      if user.using_acls?
        ids = editable_permissions.flat_map do |perm|
          group_ids = user.collections_for_permission(perm)
          next [] if group_ids.empty?

          GrdaWarehouse::GroupViewableEntity.where(
            access_group_id: group_ids,
            entity_type: 'GrdaWarehouse::Cohort',
          ).pluck(:entity_id)
        end.compact
        return none if ids.empty?

        where(id: ids)
      else
        if user.can_edit_some_cohorts? # rubocop:disable Style/IfInsideElse
          if current_scope.present?
            current_scope.merge(user.cohorts)
          else
            user.cohorts
          end
        else
          none
        end
      end
    end

    scope :cohort_search, ->(search_string) do
      # If we searched for a number, assume it's a client_id
      if search_string.to_i.to_s == search_string.to_s
        where(id: GrdaWarehouse::CohortClient.where(client_id: search_string).select(:cohort_id))
      else
        where(arel_table[:name].matches("%#{search_string}%"))
      end
    end

    def deleted_clients_tab?(population)
      return true if population.to_s == 'deleted' # backwards compatibility

      tab = cohort_tabs.find_by(name: population)
      # If the source of the clients on this tab looks for deleted clients
      tab&.base_scope == 'only_deleted'
    end

    private def active_tab(user, population)
      tab = cohort_tabs.find_by(name: population)
      return tab if tab&.show_for?(user)

      cohort_tabs.find_by(name: 'Active Clients')
    end

    def clients_for_tab(user, population, tab = nil)
      active_tab = tab || active_tab(user, population)
      cohort_clients.joins(:client).
        send(active_tab.base_scope).
        where(active_tab.cohort_client_filter)
    end

    def search_clients(page: nil, per: nil, population: :active, user:)
      @client_search_scope = clients_for_tab(user, population)
      scope = if page.present? && per.present?
        @client_search_scope.order(id: :asc).page(page).per(per)
      else
        @client_search_scope
      end

      @client_search_result = scope.preload(*preloads)
    end

    def preloads
      [
        :cohort_client_changes,
        {
          cohort_client_notes: :user,
          client: [
            :cohort_notes,
            :processed_service_history,
            :client_file_consent_forms_signed,
            :client_file_consent_forms_signed_confirmed,
            :source_exits,
            {
              cohort_clients: [
                :cohort,
              ],
              source_clients: [
                :most_recent_tc_hat,
                :most_recent_current_living_situation,
                :most_recent_pathways_or_rrh_assessment,
                :most_recent_2023_pathways_assessment,
                :most_recent_2023_transfer_assessment,
                most_recent_ce_assessment: [:user, { assessment_questions: :lookup }],
              ],
            },
          ],
        },
      ]
    end

    def sanitized_name
      # See https://www.keynotesupport.com/excel-basics/worksheet-names-characters-allowed-prohibited.shtml
      name.gsub(/['\*\/\\\?\[\]\:]/, '-')
    end

    def cohort_tabs_for_user(user)
      cohort_tabs.order(order: :asc).map do |tab|
        permission = tab.show_for?(user)
        next unless permission

        count = clients_for_tab(user, tab.name, tab).count
        [
          cohort_path(self, population: tab.name),
          {
            title: tab.name,
            permission: permission,
            count: count,
          },
        ]
      end.compact.to_h
    end

    # full un-paginated scope for the last `client_search`
    attr_reader :client_search_scope

    # paginated/preloaded scope for the last `client_search`
    attr_reader :client_search_result

    def self.has_some_cohort_access user # rubocop:disable  Naming/PredicateName
      user.can_access_some_cohorts
    end

    def user_can_edit_cohort_clients user
      user.can_edit_some_cohorts && user.cohorts.where(id: id).exists?
    end
    memoize :user_can_edit_cohort_clients

    # Used in cohort columns, cached here so we don't have to re-fetch
    def window_project_ids
      @window_project_ids ||= GrdaWarehouse::Hud::Project.joins(:data_source).
        merge(GrdaWarehouse::DataSource.visible_in_window).
        pluck(:id)
    end

    def inactive?
      !active?
    end

    def active?
      active_cohort
    end

    # Never show the cohort on the client dashboard if we haven't explicitly
    # indicated it should be shown
    # If the cohort is active and we have indicated it should be shown, show it
    # If the cohort is inactive, only show it if we indicated it should be shown even when inactive
    def should_show_on_client_dashboard?
      return false unless show_on_client_dashboard?
      return true if active?

      expose_inactive_on_client_dashboard?
    end

    def cas_tag_name
      CasAccess::Tag.find(tag_id)&.name
    rescue ActiveRecord::RecordNotFound, PG::ConnectionBad
      nil
    end

    def visible_columns(user:)
      return self.class.default_visible_columns unless column_state.present?

      active_columns.each do |column|
        column.current_user = user
      end
    end

    def active_columns
      column_state&.select(&:visible)&.presence || self.class.default_visible_columns
    end

    def self.default_visible_columns
      [
        ::CohortColumns::LastName.new,
        ::CohortColumns::FirstName.new,
      ]
    end

    def self.non_translateable
      Set.new(
        [
          ::CohortColumns::LastName,
          ::CohortColumns::FirstName,
          ::CohortColumns::Rank,
          ::CohortColumns::Age,
          ::CohortColumns::Gender,
          ::CohortColumns::Ssn,
          ::CohortColumns::ClientId,
        ],
      )
    end

    def self.excluded_from_analytics
      Set.new(
        [
          ::CohortColumns::LastName,
          ::CohortColumns::FirstName,
          ::CohortColumns::Dob,
          ::CohortColumns::Ssn,
          ::CohortColumns::Delete,
        ],
      )
    end

    def self.active_columns
      GrdaWarehouse::Cohorts::CohortColumn.active.map do |column|
        column.class_name.constantize.new
      end
    end

    def self.available_columns
      GrdaWarehouse::Cohorts::CohortColumn.all.map do |column|
        column.class_name.constantize.new
      end
    end

    # Attr Accessors
    available_columns.each do |column|
      attr_accessor column.column
    end

    def self.sort_directions
      {
        'desc' => 'Descending',
        'asc' => 'Ascending',
      }
    end

    def self.threshold_keys
      (1..visible_thresholds).map do |i|
        [
          "threshold_row_#{i}",
          "threshold_color_#{i}",
          "threshold_label_#{i}",
        ]
      end.flatten
    end

    def self.visible_thresholds
      3
    end

    def self.prepare_active_cohorts
      client_ids = GrdaWarehouse::CohortClient.joins(:cohort, :client).merge(GrdaWarehouse::Cohort.active).distinct.pluck(:client_id)
      # Don't do anything if we don't have any clients on cohorts
      return unless client_ids.present?

      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
      GrdaWarehouse::Cohort.active.find_each(&:refresh_time_dependant_client_data)
    end

    def refresh_time_dependant_client_data(cohort_client_ids: nil)
      scope = cohort_clients
      scope = scope.where(id: cohort_client_ids) if cohort_client_ids.present?
      scope.joins(:client).preload(client: :processed_service_history).find_in_batches do |batch|
        rows = []
        batch.each do |cc|
          time_dependent_methods.each do |column, meth|
            cc[column] = send(meth, cc.client)
          end
          rows << cc
        end
        GrdaWarehouse::CohortClient.import(
          rows,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: time_dependent_methods.keys,
          },
        )
      end
    end

    private def time_dependent_methods
      {
        calculated_days_homeless_on_effective_date: :calculated_days_homeless,
        days_homeless_last_three_years_on_effective_date: :days_homeless_last_three_years,
        days_literally_homeless_last_three_years_on_effective_date: :days_literally_homeless_last_three_years,
        destination_from_homelessness: :destination_from_homelessness,
        related_users: :related_users,
        disability_verification_date: :disability_verification_date,
        missing_documents: :missing_documents,
        days_homeless_plus_overrides: :days_homeless_plus_overrides,
        individual_in_most_recent_homeless_enrollment: :individual_in_most_recent_homeless_enrollment,
        most_recent_date_to_street: :most_recent_date_to_street,
        sheltered_days_homeless_last_three_years: :sheltered_days_homeless_last_three_years,
        unsheltered_days_homeless_last_three_years: :unsheltered_days_homeless_last_three_years,
        most_recent_cls: :calculated_most_recent_cls,
        most_recent_prior_living_situation: :calculated_most_recent_prior_living_situation,
        most_recent_household_type: :calculated_most_recent_household_type,
        most_recent_self_report_months_homeless: :calculated_most_recent_self_report_months_homeless,
        most_recent_disabling_condition: :calculated_most_recent_disabling_condition,
      }
    end

    private def inactive_date
      Date.current - days_of_inactivity.days
    end

    private def calculated_days_homeless(client)
      client.days_homeless(on_date: effective_date || Date.current)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.homeless_counts to accept client_ids and a date
    end

    private def sheltered_days_homeless_last_three_years(client)
      client.sheltered_days_homeless_last_three_years
    end

    private def unsheltered_days_homeless_last_three_years(client)
      client.unsheltered_days_homeless_last_three_years
    end

    private def days_homeless_last_three_years(client)
      client.days_homeless_in_last_three_years(on_date: effective_date || Date.current)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.all_homeless_in_last_three_years to accept client_ids and a date
    end

    private def days_literally_homeless_last_three_years(client)
      client.literally_homeless_last_three_years(on_date: effective_date || Date.current)

      # TODO, make this work on a batch of clients
      # Convert GrdaWarehouse::WarehouseClientsProcessed.all_literally_homeless_last_three_years to accept client_ids and a date
    end

    private def destination_from_homelessness(client)
      client.permanent_source_exits_from_homelessness.
        where(ex_t[:ExitDate].gteq(90.days.ago.to_date)).
        pluck(:ExitDate, :Destination).map do |exit_date, destination|
          "<span class='hidden'>#{exit_date.to_fs(:db)}</span>#{exit_date} to #{HudUtility2024.destination(destination)}"
        end.join('; ')
    end

    private def individual_in_most_recent_homeless_enrollment(client)
      most_recent_enrollment = client.service_history_enrollments.entry.homeless.order(first_date_in_program: :desc).first
      most_recent_enrollment&.presented_as_individual
    end

    # Returns the most recent value for 3.917.3 DateToStreetESSH based on EntryDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to Enrollments at projects in the project group
    private def most_recent_date_to_street(client)
      scope = GrdaWarehouse::Hud::Enrollment.order(entry_date: :desc, date_updated: :desc).
        joins(:project, client: :warehouse_client_source)
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope.homeless, client)
      end
      return unless item

      item.DateToStreetESSH
    end

    private def related_users(client)
      client_users = client.user_clients.
        non_confidential.
        active.
        pluck(:user_id, :relationship).to_h
      User.where(id: client_users.keys).map { |u| "#{client_users[u.id]} (#{u.name})" }.join('; ')
    end

    private def missing_documents(client)
      required_documents = GrdaWarehouse::AvailableFileTag.document_ready
      client.document_readiness(required_documents).select do |m|
        m.available == false
      end.map(&:name).join('; ')
    end

    private def disability_verification_date(client)
      client.most_recent_verification_of_disability&.created_at&.to_date
    end

    private def days_homeless_plus_overrides(client)
      client.processed_service_history&.days_homeless_plus_overrides
    end

    private def most_recent_automaintained_data_item(scope, client)
      scope.merge(GrdaWarehouse::WarehouseClient.where(destination_id: client.id)).
        merge(GrdaWarehouse::Hud::Project.joins(:project_groups).merge(GrdaWarehouse::ProjectGroup.where(id: project_group_id))).
        first
    end

    private def most_recent_un_automaintained_data_item(scope, client)
      scope.merge(GrdaWarehouse::WarehouseClient.where(destination_id: client.id)).
        first
    end

    # Most recent CLS based on InformationDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to CLS at projects in the project group
    private def calculated_most_recent_cls(client)
      scope = GrdaWarehouse::Hud::CurrentLivingSituation.order(information_date: :desc, date_updated: :desc).
        joins(enrollment: [:project, client: :warehouse_client_source])
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope, client)
      end
      return unless item

      "#{item.situation_label} on #{item.information_date} at #{item.enrollment.project.name}"
    end

    # Most recent prior LivingSituation based on EntryDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to Enrollments at projects in the project group
    private def calculated_most_recent_prior_living_situation(client)
      scope = GrdaWarehouse::Hud::Enrollment.order(entry_date: :desc, date_updated: :desc).
        joins(:project, client: :warehouse_client_source)
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope, client)
      end
      return unless item

      "#{item.prior_living_situation_label} on #{item.entry_date} at #{item.project.name}"
    end

    # Household type form the most recent enrollment based on EntryDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to Enrollments at projects in the project group
    private def calculated_most_recent_household_type(client)
      scope = GrdaWarehouse::Hud::Enrollment.order(entry_date: :desc, date_updated: :desc).
        joins(:project, client: :warehouse_client_source)
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope, client)
      end
      return unless item

      # NOTE: we may want to figure out how to batch preload household members in the future
      # at the moment, we use the default which loads clients for each enrollment
      "#{item.household_type} on #{item.entry_date} at #{item.project.name}"
    end

    # Returns the most recent value for 3.917.5 MonthsHomelessPastThreeYears based on EntryDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to Enrollments at projects in the project group
    private def calculated_most_recent_self_report_months_homeless(client)
      scope = GrdaWarehouse::Hud::Enrollment.order(entry_date: :desc, date_updated: :desc).
        joins(:project, client: :warehouse_client_source)
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope, client)
      end
      return unless item&.months_homeless_past_three_years
      # Ignore any unknown values
      return unless item.months_homeless_past_three_years > 100

      "#{HudUtility2024.months_homeless_past_three_years(item.months_homeless_past_three_years)} on #{item.entry_date} at #{item.project.name}"
    end

    # Returns the most recent value for DisablingCondition based on EntryDate desc, DateUpdated desc
    # If the cohort is auto maintained, limit to Enrollments at projects in the project group
    private def calculated_most_recent_disabling_condition(client)
      scope = GrdaWarehouse::Hud::Enrollment.order(entry_date: :desc, date_updated: :desc).
        joins(:project, client: :warehouse_client_source)
      item = if auto_maintained?
        most_recent_automaintained_data_item(scope, client)
      else
        most_recent_un_automaintained_data_item(scope, client)
      end
      return unless item&.disabling_condition

      "#{HudUtility2024.no_yes_reasons_for_missing_data(item.disabling_condition)} on #{item.entry_date} at #{item.project.name}"
    end

    private def maintain_system_group
      AccessGroup.delayed_system_group_maintenance(group: :cohorts)
      Collection.delayed_system_group_maintenance(group: :cohorts)
    end

    def self.maintain_auto_maintained!
      auto_maintained.find_each(&:maintain)
    end

    def auto_maintained?
      project_group.present?
    end

    def selected_project_group_viewable_by(user)
      return true if project_group.blank?

      GrdaWarehouse::ProjectGroup.viewable_by(user).exists?(project_group.id)
    end

    def project_group_options_for_select(user)
      options = GrdaWarehouse::ProjectGroup.options_for_select(user: user)
      # Add the current selected option to the selectable list so it doesn't get overwritten
      # if the user has the ability to edit the cohort but can't view the selected project group
      if project_group.present? && !selected_project_group_viewable_by(user)
        current_selected_data = [[project_group.name, project_group.id]]
        options |= current_selected_data
      end
      options.sort
    end

    def maintain
      return unless auto_maintained?

      existing_client_ids = cohort_clients.pluck(:client_id)
      incoming_client_ids = project_group.clients.
        joins(:warehouse_client_source).
        merge(GrdaWarehouse::Hud::Enrollment.open_on_date(Date.current)).
        pluck(wc_t[:destination_id])
      to_remove = existing_client_ids - incoming_client_ids
      to_add = incoming_client_ids - existing_client_ids
      remove_clients(to_remove, 'No longer enrolled in project group')
      add_clients(to_add, 'Enrolled in project group')
    end

    private def add_clients(client_ids, reason)
      @processing_date ||= Date.current
      system_user_id = User.setup_system_user.id
      client_ids -= cohort_clients.pluck(:client_id) # Do not touch existing clients
      cohort_clients_by_client_id = cohort_clients.only_deleted.where(client_id: client_ids).index_by(&:client_id)
      cohort_client_batch = []
      client_ids.uniq.each do |client_id|
        # Create (or resurrect) added clients
        cohort_client = cohort_clients_by_client_id[client_id] || GrdaWarehouse::CohortClient.new(cohort_id: id, client_id: client_id)
        cohort_client.deleted_at = nil

        # Set any default columns
        self.class.available_columns.each do |column|
          if column.default_value?
            column.cohort = self
            cohort_client[column.column] = column.default_value(client_id)
          end
          # Enforce that we added the client on the processing date
          cohort_client[:date_added_to_cohort] = @processing_date
        end

        cohort_client_batch << cohort_client
      end

      # Save the cohort clients, and log the create reasons
      update_columns = self.class.available_columns.map { |c| c.column.to_sym if c.column_editable? }.compact.uniq + [:deleted_at]
      results = GrdaWarehouse::CohortClient.import!(
        cohort_client_batch,
        on_duplicate_key_update: { columns: update_columns },
      )
      changes_batch = []
      results.ids.each do |cohort_client_id|
        changes_batch << cohort_client_changes_source.new(
          cohort_id: id,
          cohort_client_id: cohort_client_id,
          user_id: system_user_id,
          change: 'create',
          reason: reason,
          changed_at: @processing_date,
        )
      end
      cohort_client_changes_source.import(changes_batch)
      client_ids
    end

    private def remove_clients(client_ids, reason)
      return unless client_ids

      @processing_date ||= Date.current
      system_user_id = User.setup_system_user.id
      cc_ids = cohort_clients.where(client_id: client_ids).pluck(:id)
      cohort_clients.where(client_id: client_ids).update_all(deleted_at: Time.current)
      cohort_client_changes_source.import(
        cc_ids.map do |cc_id|
          cohort_client_changes_source.new(
            cohort_id: id,
            cohort_client_id: cc_id,
            user_id: system_user_id,
            change: 'destroy',
            reason: reason,
            changed_at: @processing_date,
          )
        end,
      )
      client_ids
    end

    private def cohort_client_changes_source
      GrdaWarehouse::CohortClientChange
    end

    private def editable_role_name
      'System Role - Can Participate in Cohorts'
    end

    private def viewable_role_name
      'System Role - Can View Cohorts'
    end

    def self.editable_permission
      :can_participate_in_cohorts
    end

    def self.viewable_permission
      :can_view_cohorts
    end

    def self.viewable_permissions
      [
        viewable_permission,
      ]
    end

    def self.editable_permissions
      [
        :can_manage_cohort_data,
        editable_permission,
      ]
    end

    def entity_relation_type
      :cohorts
    end

    def collection_type
      'Cohorts'
    end
  end
end
