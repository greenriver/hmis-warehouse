###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  module FormTransfer
    # Imports organizations and projects (with funders, ProjectCoCs, and inventory) by HUD ID, and
    # answers which local record stands in for a source HUD ID.
    class ProjectImporter
      include Logging

      # @param name_prefix [String, nil] prepended to organization and project names
      def initialize(payload, data_source_id:, user_id:, name_prefix:, output:)
        @payload = payload
        @data_source_id = data_source_id
        @user_id = user_id
        @name_prefix = name_prefix
        @output = output
        @resolver = HudKeyResolver.new(data_source_id: data_source_id)
        @projects = {}
        @organizations = {}
      end

      def run
        @payload.fetch('organizations', []).each { |attrs| import_organization(attrs) }
        @payload.fetch('projects', []).each { |attrs| import_project(attrs) }
      end

      # The imported copy when the payload has projects; otherwise a local project with the same HUD ID.
      # @return [Hmis::Hud::Project, nil]
      def find_project(source_project_id)
        return if source_project_id.blank?
        return @projects[source_project_id] if @payload.fetch('projects', []).any?

        Hmis::Hud::Project.find_by(data_source_id: @data_source_id, ProjectID: source_project_id)
      end

      # @return [Hmis::Hud::Organization, nil]
      def find_organization(source_organization_id)
        return if source_organization_id.blank?
        return @organizations[source_organization_id] if @payload.fetch('organizations', []).any?

        Hmis::Hud::Organization.find_by(data_source_id: @data_source_id, OrganizationID: source_organization_id)
      end

      private

      def import_organization(attrs)
        name = prefixed(attrs['OrganizationName'])
        organization = @resolver.resolve(Hmis::Hud::Organization, attrs['OrganizationID'], same_record: ->(r) { r.OrganizationName == name })
        copy(organization, attrs, 'OrganizationName' => name)
        log_hud_save(organization, "organization #{name} (#{organization.OrganizationID})")
        @organizations[attrs['OrganizationID']] = organization
      end

      def import_project(attrs)
        name = prefixed(attrs['ProjectName'])
        organization = @organizations[attrs['OrganizationID']]
        return log("SKIP project #{attrs['ProjectName']}: its organization is not in the file") unless organization

        project = @resolver.resolve(Hmis::Hud::Project, attrs['ProjectID'], same_record: ->(r) { r.ProjectName == name })
        copy(project, attrs, 'ProjectName' => name, 'OrganizationID' => organization.OrganizationID)
        log_hud_save(project, "project #{name} (#{project.ProjectID})")
        @projects[attrs['ProjectID']] = project

        HudColumns::PROJECT_CHILDREN.each do |association, class_name|
          attrs.fetch(association, []).each { |child_attrs| import_project_child(class_name.constantize, child_attrs, project) }
        end
      end

      def import_project_child(klass, attrs, project)
        key_column = klass.hud_key.to_s
        child = @resolver.resolve(klass, attrs.fetch(key_column), same_record: ->(r) { r.ProjectID == project.ProjectID })
        copy(child, attrs, 'ProjectID' => project.ProjectID)
        log_hud_save(child, "#{klass.name.demodulize} #{child[key_column]} for #{project.ProjectID}")
      end

      # Only the exported columns, minus the HUD key, which the resolver already chose.
      def copy(record, attrs, overrides)
        columns = HudColumns.for(record.class) - [record.class.hud_key.to_s]
        record.assign_attributes(attrs.slice(*columns).merge(overrides, 'DateDeleted' => nil))
        record.user_id ||= @user_id
      end

      # HUD validators can reject historical data the source already accepted (dates that no
      # longer line up, for example), so copies skip validation.
      def log_hud_save(record, label)
        log_save(record, label, validate: false)
      end

      def prefixed(name)
        return name if @name_prefix.blank? || name.start_with?(@name_prefix)

        "#{@name_prefix}#{name}"
      end
    end
  end
end
