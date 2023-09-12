###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module GrdaWarehouse
  class ProjectGroup < GrdaWarehouseBase
    include ArelHelper
    include AccessGroups # TODO: START_ACL remove after migration to ACLs
    include EntityAccess
    acts_as_paranoid
    has_paper_trail

    attr_accessor :editor_ids

    validates_presence_of :name
    after_create :maintain_system_group

    has_and_belongs_to_many :projects, class_name: 'GrdaWarehouse::Hud::Project', join_table: :project_project_groups
    has_many :clients, through: :projects

    # START_ACL remove after migration to ACLs
    has_many :group_viewable_entities, -> { where(entity_type: 'GrdaWarehouse::ProjectGroup') }, class_name: 'GrdaWarehouse::GroupViewableEntity', foreign_key: :entity_id
    # NOTE: these are in the app DB
    has_many :access_groups, through: :group_viewable_entities
    has_many :access_controls, through: :access_groups
    # has_many :users, through: :access_controls
    # END_ACL

    # NOTE: these are in the app DB
    has_many :collections, through: :group_viewable_entities
    has_many :access_controls, through: :collections
    # has_many :users, through: :access_controls

    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_many :cohorts, class_name: 'GrdaWarehouse::Cohort'
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'

    has_many :contacts, through: :projects
    has_many :organization_contacts, through: :projects

    scope :viewable_by, ->(user) do
      # TODO: We may want to build a read-only version of project groups
      # so someone can see the makeup of the project groups assigned to them,
      # but be able to add or remove projects.
      # This probably doesn't need a new permission, project groups would just be visible
      # if the user has access to use any project groups for reporting.
      editable_by(user)
    end

    # TODO: START_ACL cleanup after migration to ACLs
    scope :editable_by, ->(user) do
      return none unless user.present?

      if user.using_acls?
        return unless editable_permissions.map { |perm| user.send("#{perm}?") }.any?

        ids = editable_permissions.flat_map do |perm|
          group_ids = user.collections_for_permission(perm)
          next [] if group_ids.empty?

          GrdaWarehouse::GroupViewableEntity.where(
            collection_id: group_ids,
            entity_type: 'GrdaWarehouse::ProjectGroup',
          ).pluck(:entity_id)
        end.compact
        return none if ids.empty?

        where(id: ids)
      else
        if user.can_edit_project_groups? # rubocop:disable Style/IfInsideElse
          current_scope
        elsif user.can_edit_assigned_project_groups?
          if current_scope.present?
            current_scope.merge(user.project_groups)
          else
            user.project_groups
          end
        else
          none
        end
      end
    end
    # END_ACL

    scope :text_search, ->(text) do
      query = text.gsub(/[^0-9a-zA-Z ]/, '')
      return none unless query.present?

      distinct.left_outer_joins(:projects).
        where(
          arel_table[:name].lower.matches("%#{query.downcase}%").
          or(p_t[:ProjectName].lower.matches("%#{query.downcase}%")),
        )
    end

    def available_for_delete?
      ! used_for_cas_sync? && ! cohorts.exists?
    end

    # This is called in the Hourly scheduled task
    # It will attempt to upgrade any un-upgraded project groups to the
    # filter version and then will ensure project lists align with
    # any recent changes (new projects being added that fall within the filter scope)
    def self.maintain_project_lists!
      find_each do |group|
        group.convert_to_filter!
        group.maintain_projects!
      end
    end

    def self.options_for_select(user:)
      if user.using_acls?
        collection_ids = user.collections_for_permission(:can_view_assigned_reports)
        return [] if collection_ids.empty?

        GrdaWarehouse::GroupViewableEntity.where(
          collection_id: collection_ids,
          entity_type: 'GrdaWarehouse::ProjectGroup',
        ).pluck(:entity_id)
      else
        user.project_groups.distinct.order(name: :asc).pluck(:name, :id)
      end
    end

    private def maintain_system_group
      AccessGroup.delayed_system_group_maintenance(group: :project_groups)
    end

    def filter
      @filter ||= begin
        f = ::Filters::HudFilterBase.new(user_id: User.setup_system_user.id).update(options)
        f.coc_codes = []
        f
      end
    end

    # NOTE: we only care about Data Sources, Organizations, Projects, and Project Types
    def describe_filter_as_html
      keys = [
        :project_type_numbers,
        :project_ids,
        :organization_ids,
        :data_source_ids,
      ]
      filter.describe_filter_as_html(keys)
    end

    private def save_filter!
      update(options: filter.to_h)
    end

    def maintain_projects!
      self.projects = GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids)
    end

    # NOTE: this should only be run during the initial conversion to filters, or it will explicitly
    # set project_ids where it might make more sense to use higher level ids
    def convert_to_filter!
      return unless options == {}

      project_ids = projects.pluck(:id)
      filter.update({ project_ids: project_ids })
      save_filter!
    end

    def any_contacts?
      contacts.any? || organization_contacts.any?
    end

    def used_for_cas_sync?
      return unless GrdaWarehouse::Config.get(:cas_available_method).to_sym == :project_group

      GrdaWarehouse::Config.get(:cas_sync_project_group_id) == id
    end

    def self.import_csv(file)
      parsed = csv(file)
      original = parsed.dup
      errors = []
      unless check_header!(parsed)
        errors << {
          file: 'Incorrect file format',
          message: 'The file must contain at least one project, and the header row of the uploaded file must match the description below.',
        }
        return errors
      end

      all_projects = GrdaWarehouse::Hud::Project.pluck(:id, :ProjectID, :data_source_id).map do |id, project_id, data_source_id|
        [
          [project_id.to_s, data_source_id.to_s],
          id,
        ]
      end.to_h
      all_project_keys = all_projects.keys

      parsed.reject! { |row| row.values.map(&:blank?).any? }
      parsed.select! { |row| all_project_keys.include?([row['ProjectID'].to_s, row['data_source_id'].to_s]) }
      (original - parsed).each do |row|
        errors << row
      end
      # errors << "Excluded #{ActionController::Base.helpers.pluralize(input_count - parsed.count, 'project')}" if (input_count - parsed.count).positive?
      return errors if parsed.empty?

      parsed.group_by { |row| row['ProjectGroupName'] }.each do |group_name, rows|
        group = where(name: group_name).first_or_create
        incoming_projects = rows.map { |row| [row['ProjectID'].to_s, row['data_source_id'].to_s] }
        project_ids = all_projects.select { |key, _id| incoming_projects.include?(key) }.values
        transaction do
          group.update(options: group.filter.update({ project_ids: project_ids }).to_h)
          # NOTE: maybe the next two lines should just call maintain_projects!
          group.projects.delete_all
          group.projects = GrdaWarehouse::Hud::Project.where(id: project_ids)
        end
      end
      errors
    end

    def self.csv(file)
      if file.content_type.in?(['text/plain', 'text/csv', 'application/csv'])
        sheet = ::Roo::CSV.new(StringIO.new(file.read))
        sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
      else
        sheet = ::Roo::Excelx.new(StringIO.new(file.read).binmode)
        return nil if sheet&.first_row.blank?

        sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
      end
    end

    def self.check_header!(csv)
      return false if csv.empty?

      csv.first.keys == expected_csv_headers
    end

    def self.expected_csv_headers
      [
        'ProjectGroupName',
        'ProjectName',
        'ProjectID',
        'data_source_id',
      ]
    end

    def effective_project_ids
      filter.effective_project_ids
    end

    def project_ids
      filter.project_ids
    end

    def project_ids=(ids)
      filter.update(project_ids: ids)
      save_filter!
    end

    def organization_ids
      filter.organization_ids
    end

    def organization_ids=(ids)
      filter.update(organization_ids: ids)
      save_filter!
    end

    def project_type_numbers
      filter.project_type_numbers
    end

    def project_type_numbers=(ids)
      filter.update(project_type_numbers: ids)
      save_filter!
    end

    def data_source_ids
      filter.data_source_ids
    end

    def data_source_ids=(ids)
      filter.update(data_source_ids: ids)
      save_filter!
    end

    private def editable_role_name
      'System Role - Can Edit Project Groups'
    end

    def self.editable_permission
      :can_edit_project_groups
    end

    def self.editable_permissions
      [
        :can_edit_assigned_project_groups,
        editable_permission,
      ]
    end

    def entity_relation_type
      :project_groups
    end
  end
end
