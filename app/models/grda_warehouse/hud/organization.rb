###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# these are also sometimes called agencies
module GrdaWarehouse::Hud
  class Organization < Base
    include ArelHelper
    include HudSharedScopes
    self.table_name = 'Organization'
    self.hud_key = :OrganizationID
    acts_as_paranoid column: :DateDeleted
    has_many :projects, **hud_assoc(:OrganizationID, 'Project'), inverse_of: :organization
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :organizations
    belongs_to :data_source, inverse_of: :organizations

    has_many :service_history_enrollments, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID], inverse_of: :organization
    has_many :contacts, class_name: 'GrdaWarehouse::Contact::Organization', foreign_key: :entity_id

    accepts_nested_attributes_for :projects

    # NOTE: you need to add a distinct to this or group it to keep from getting repeats
    scope :residential, -> {
      joins(:projects).where(
        Project.arel_table[:ProjectType].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS)
      )
    }

    scope :dmh, -> do
      where(dmh: true)
    end
    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      else
        qc = -> (s) { connection.quote_column_name s }
        q  = -> (s) { connection.quote s }

        where(
          [
            has_access_to_organization_through_viewable_entities(user, q, qc),
            has_access_to_organization_through_data_source(user, q, qc),
            has_access_to_organization_through_projects(user, q, qc)
          ].join ' OR '
        )
      end
    end
    scope :editable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      else
        qc = -> (s) { connection.quote_column_name s }
        q  = -> (s) { connection.quote s }

        where [
          has_access_to_organization_through_viewable_entities(user, q, qc),
          has_access_to_organization_through_data_source(user, q, qc)
        ].join ' OR '
      end
    end

    # def self.bed_utilization_by_project filter:
    #   user = filter.user
    #   # you wouldn't think it would need to be as complicated as this, but Arel complained until I got it just right
    #   project_cols = [:id, :data_source_id, :ProjectID, :ProjectName, GrdaWarehouse::Hud::Project.project_type_column]
    #   project_scope_for_user(user).
    #     joins( :service_history, :organization ).
    #     merge(self.residential).
    #     where( o_t[:OrganizationID].eq filter.organization.OrganizationID ).
    #     where( o_t[:data_source_id].eq filter.organization.data_source_id ).
    #     where( sh_t[:date].between(filter.range) ).
    #     group( *project_cols.map{ |cn| p_t[cn] }, sh_t[:date] ).
    #     order( p_t[:ProjectName].asc, sh_t[:date].asc ).
    #     select( *project_cols.map{ |cn| p_t[cn] }, sh_t[:date].as('date'), nf( 'COUNT', [nf( 'DISTINCT', [sh_t[:client_id]] )] ).as('client_count') ).
    #     includes(:inventories).
    #     group_by(&:id)
    # end

    def self.project_scope_for_user user=nil
      if user.present?
        GrdaWarehouse::Hud::Project.viewable_by(user)
      else
        GrdaWarehouse::Hud::Project
      end
    end

    private_class_method def self.has_access_to_organization_through_viewable_entities(user, q, qc)
      viewability_table  = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      organization_table = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end
      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            WHERE
              #{viewability_table}.#{qc.('entity_id')}   = #{organization_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
              AND
              #{organization_table}.#{qc.(GrdaWarehouse::Hud::Organization.paranoia_column)} IS NULL
        )

      SQL
    end

    private_class_method def self.has_access_to_organization_through_data_source(user, q, qc)
      data_source_table  = GrdaWarehouse::DataSource.quoted_table_name
      viewability_table  = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      organization_table = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{data_source_table}
            ON
              #{viewability_table}.#{qc.('entity_id')}   = #{data_source_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::DataSource.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
            WHERE
              #{organization_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
        )

      SQL
    end

    private_class_method def self.has_access_to_organization_through_projects(user, q, qc)
      viewability_table  = GrdaWarehouse::GroupViewableEntity.quoted_table_name
      project_table      = GrdaWarehouse::Hud::Project.quoted_table_name
      organization_table = quoted_table_name
      viewability_deleted_column_name = GrdaWarehouse::GroupViewableEntity.paranoia_column
      group_ids = user.access_groups.pluck(:id)
      group_id_query = if group_ids.empty?
        "0=1"
      else
        "#{viewability_table}.#{qc.('access_group_id')} IN (#{group_ids.join(', ')})"
      end

      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            INNER JOIN
            #{project_table}
            ON
              #{viewability_table}.#{qc.('entity_id')}   = #{project_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::Hud::Project.sti_name)}
              AND
              #{group_id_query}
              AND
              #{viewability_table}.#{qc.(viewability_deleted_column_name)} IS NULL
            WHERE
              #{project_table}.#{qc.('data_source_id')} = #{organization_table}.#{qc.('data_source_id')}
              AND
              #{project_table}.#{qc.('OrganizationID')} = #{organization_table}.#{qc.('OrganizationID')}
              AND
              #{project_table}.#{qc.(GrdaWarehouse::Hud::Project.paranoia_column)} IS NULL
        )

      SQL
    end

    def self.hud_csv_headers(version: nil)
      case version
      when '2020'
        [
          :OrganizationID,
          :OrganizationName,
          :VictimServicesProvider,
          :OrganizationCommonName,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :OrganizationID,
          :OrganizationName,
          :OrganizationCommonName,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    # when we export, we always need to replace OrganizationID with the value of id
    def self.to_csv(scope:)
      attributes = self.hud_csv_headers.dup
      headers = attributes.clone
      attributes[attributes.index(:OrganizationID)] = :id


      CSV.generate(headers: true) do |csv|
        csv << headers

        scope.each do |i|
          csv << attributes.map{ |attr| i.send(attr) }
        end
      end
    end

    def self.names
      select(:OrganizationID, :OrganizationName).distinct.pluck(:OrganizationName, :OrganizationID)
    end

    def project_names
      projects.order(ProjectName: :asc).pluck(:ProjectName)
    end

    alias_attribute :name, :OrganizationName

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"

      where(
        arel_table[:OrganizationName].matches(query)
      )
    end

    def self.options_for_select user:
      # don't cache this, it's a class method
      @options = begin
        options = {}
        viewable_by(user).
          joins(:data_source).
          order(ds_t[:name].asc, OrganizationName: :asc).
          pluck(ds_t[:name].as('ds_name').to_sql, :OrganizationName, :id).each do |ds, org_name, id|
            options[ds] ||= []
            options[ds] << [org_name, id]
          end
        options
      end
    end
  end
end