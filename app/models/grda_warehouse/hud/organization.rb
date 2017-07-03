# these are also sometimes called agencies
module GrdaWarehouse::Hud
  class Organization < Base
    self.table_name = 'Organization'
    self.hud_key = 'OrganizationID'
    acts_as_paranoid column: :DateDeleted
    has_many :projects, **hud_many(Project), inverse_of: :organization
    belongs_to :export, **hud_belongs(Export), inverse_of: :organizations
    belongs_to :data_source, inverse_of: :organizations
    has_many :service_histories, 
      class_name: 'GrdaWarehouse::ServiceHistory',
      foreign_key: [:data_source_id, :organization_id], primary_key: [:data_source_id, :OrganizationID],
      inverse_of: :organization
    has_many :contacts, class_name: GrdaWarehouse::Contact::Organization.name, foreign_key: :entity_id
    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::UserViewableEntity'

    accepts_nested_attributes_for :projects

    # NOTE: you need to add a distinct to this or group it to keep from getting repeats
    scope :residential, -> {
      joins(:projects).where(
        Project.arel_table[:ProjectType].in Project::RESIDENTIAL_PROJECT_TYPE_IDS
      )
    }
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

    private_class_method def self.has_access_to_organization_through_viewable_entities(user, q, qc)
      viewability_table  = GrdaWarehouse::UserViewableEntity.quoted_table_name
      organization_table = quoted_table_name
        
      <<-SQL.squish

        EXISTS (
          SELECT 1 FROM
            #{viewability_table}
            WHERE
              #{viewability_table}.#{qc.('entity_id')}   = #{organization_table}.#{qc.('id')}
              AND
              #{viewability_table}.#{qc.('entity_type')} = #{q.(sti_name)}
              AND
              #{viewability_table}.#{qc.('user_id')}     = #{user.id}
        )

      SQL
    end

    private_class_method def self.has_access_to_organization_through_data_source(user, q, qc)
      data_source_table  = GrdaWarehouse::DataSource.quoted_table_name
      viewability_table  = GrdaWarehouse::UserViewableEntity.quoted_table_name
      organization_table = quoted_table_name
        
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
              #{viewability_table}.#{qc.('user_id')}     = #{user.id}
            WHERE
              #{organization_table}.#{qc.('data_source_id')} = #{data_source_table}.#{qc.('id')}
        )

      SQL
    end

    private_class_method def self.has_access_to_organization_through_projects(user, q, qc)
      viewability_table  = GrdaWarehouse::UserViewableEntity.quoted_table_name
      project_table      = GrdaWarehouse::Hud::Project.quoted_table_name
      organization_table = quoted_table_name
        
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
              #{viewability_table}.#{qc.('user_id')}     = #{user.id}
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
      [
        "OrganizationID",
        "OrganizationName",
        "OrganizationCommonName",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    # when we export, we always need to replace OrganizationID with the value of id
    def self.to_csv(scope:)
      attributes = self.hud_csv_headers
      headers = attributes.clone
      attributes[attributes.index('OrganizationID')] = 'id'


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

    alias_attribute :name, :OrganizationName

    def self.text_search(text)
      return none unless text.present?

      query = "%#{text}%"

      where(
        arel_table[:OrganizationName].matches(query)
      )
    end

  end
end