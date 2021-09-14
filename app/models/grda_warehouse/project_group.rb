###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module GrdaWarehouse
  class ProjectGroup < GrdaWarehouseBase
    include ArelHelper
    include AccessGroups
    acts_as_paranoid
    has_paper_trail

    after_create :maintain_system_group

    has_and_belongs_to_many :projects, class_name: 'GrdaWarehouse::Hud::Project', join_table: :project_project_groups

    has_many :data_quality_reports, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'
    has_one :current_data_quality_report, -> do
      where(processing_errors: nil).where.not(completed_at: nil).order(created_at: :desc).limit(1)
    end, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base'

    has_many :contacts, through: :projects
    has_many :organization_contacts, through: :projects

    scope :viewable_by, ->(user) do
      if user.can_edit_project_groups?
        current_scope
      else
        if current_scope.present?
          current_scope.merge(user.project_groups)
        else
          user.project_groups
        end
      end
    end
    scope :editable_by, ->(user) do
      viewable_by(user)
    end

    scope :text_search, ->(text) do
      query = text.gsub(/[^0-9a-zA-Z ]/, '')
      return none unless query.present?

      distinct.left_outer_joins(:projects).
        where(
          arel_table[:name].lower.matches("%#{query.downcase}%").
          or(p_t[:ProjectName].lower.matches("%#{query.downcase}%"))
        )
    end

    def self.options_for_select(user:)
      viewable_by(user).distinct.order(name: :asc).pluck(:name, :id)
    end

    private def maintain_system_group
      AccessGroup.delayed_system_group_maintenance(group: :project_groups)
    end

    def self.import_csv(file)
      parsed = csv(file)
      original = parsed.dup
      errors = []
      unless check_header!(parsed)
        errors << 'Incorrect headers'
        return errors
      end

      if parsed.empty?
        errors << 'No projects found'
        return errors
      end

      input_count = parsed.count
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

      parsed.group_by{|row| row['ProjectGroupName']}.each do |group_name, rows|
        group = where(name: group_name).first_or_create
        incoming_projects = rows.map { |row| [row['ProjectID'].to_s, row['data_source_id']] }
        project_ids = all_projects.select { |key, id| incoming_projects.include?(key) }.values
        transaction do
          group.projects.delete_all
          group.projects = GrdaWarehouse::Hud::Project.where(id: project_ids)
        end
      end
      errors
    end

    def self.csv(file)
      if file.content_type.in?(['text/plain', 'text/csv', 'application/csv'])
        sheet = ::Roo::CSV.new(StringIO.new(file.read))
        sheet.parse(headers: true).drop(1)
      else
        sheet = ::Roo::Excelx.new(StringIO.new(file.read).binmode)
        return nil if sheet&.first_row.blank?

        sheet.parse(headers: true).drop(1)
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
  end
end
