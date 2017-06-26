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
    has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::Hud::UserViewableEntity'

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
        ds_t = GrdaWarehouse::DataSource.quoted_table_name
        ve_t = GrdaWarehouse::Hud::UserViewableEntity.quoted_table_name
        p_t  = GrdaWarehouse::Hud::Project.quoted_table_name
        o_t  = quoted_table_name
        
        qc = -> (s) { connection.quote_column_name s }
        q  = -> (s) { connection.quote s }

        where(
          <<-SQL.squish

            EXISTS (
              SELECT 1 FROM
                #{ve_t}
                WHERE
                  #{ve_t}.#{qc.('entity_id')}   = #{o_t}.#{qc.('id')}
                  AND
                  #{ve_t}.#{qc.('entity_type')} = #{q.(sti_name)}
                  AND
                  #{ve_t}.#{qc.('user_id')}     = #{user.id}
            )
          OR
            EXISTS (
              SELECT 1 FROM
                #{ve_t}
                INNER JOIN
                #{ds_t}
                ON
                  #{ve_t}.#{qc.('entity_id')}   = #{ds_t}.#{qc.('id')}
                  AND
                  #{ve_t}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::DataSource.sti_name)}
                  AND
                  #{ve_t}.#{qc.('user_id')}     = #{user.id}
                WHERE
                  #{o_t}.#{qc.('data_source_id')} = #{ds_t}.#{qc.('id')}
            )
          OR
            EXISTS (
              SELECT 1 FROM
                #{ve_t}
                INNER JOIN
                #{p_t}
                ON
                  #{ve_t}.#{qc.('entity_id')}   = #{p_t}.#{qc.('id')}
                  AND
                  #{ve_t}.#{qc.('entity_type')} = #{q.(GrdaWarehouse::Hud::Project.sti_name)}
                  AND
                  #{ve_t}.#{qc.('user_id')}     = #{user.id}
                WHERE
                  #{p_t}.#{qc.('data_source_id')} = #{o_t}.#{qc.('data_source_id')}
                  AND
                  #{p_t}.#{qc.('OrganizationID')} = #{o_t}.#{qc.('OrganizationID')}
                  AND
                  #{p_t}.#{qc.('DateDeleted')} IS NULL
            )

          SQL
        )
      end
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