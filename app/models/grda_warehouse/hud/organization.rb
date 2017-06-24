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
      if user.roles.where( can_view_everything: true ).exists?
        current_scope
      else
        # unfortunately an arel bug prevented our using a much simpler query using existence subqueries
        ds_at = Arel::Table.new GrdaWarehouse::DataSource.table_name
        v_at  = Arel::Table.new GrdaWarehouse::Hud::UserViewableEntity.table_name
        v_at2 = Arel::Table.new v_at.table_name
        v_at3 = Arel::Table.new v_at.table_name
        p_at  = Arel::Table.new GrdaWarehouse::Hud::Project.table_name
        o_at  = arel_table
        ij_t = Arel::Table.new 'ijo_t'
        # add some aliases to make this more composable
        pfx = "o_vb_"
        ds_at.table_alias  = "#{pfx}_ds_at"
        v_at.table_alias   = "#{pfx}_v_at"
        v_at2.table_alias  = "#{pfx}_v_at2"
        v_at3.table_alias  = "#{pfx}_v_at3"
        p_at.table_alias   = "#{pfx}_p_at"
        ds_to_v = ds_at.join( v_at, Arel::Nodes::OuterJoin ).
          on(
              v_at[:entity_type].eq(GrdaWarehouse::DataSource.sti_name).
            and(
              v_at[:entity_id].  eq o_at[:data_source_id]
            ).
            and(
              v_at[:user_id].    eq user.id
            )
          ).
          join_sources
        o_to_v = o_at.join( 
            v_at2,
            Arel::Nodes::OuterJoin
          ).
          on(
              v_at2[:entity_type].eq(sti_name).
            and(
              v_at2[:user_id].    eq user.id
            ).
            and(
              v_at2[:entity_id].  eq o_at[:id]
              )
          ).
          join_sources
        p_to_v = p_at.join( 
            v_at3.join(p_at).
              project( p_at[:data_source_id], p_at[:OrganizationID] ).
              on(
                  v_at3[:entity_type].eq(GrdaWarehouse::Hud::Project.sti_name).
                and(
                  v_at3[:entity_id].eq p_at[:id]
                ).
                and(
                  v_at3[:user_id].eq user.id
                ).
                and(
                  p_at[:DateDeleted].not_eq nil
                )
              ).
              as(ij_t.table_name),
            Arel::Nodes::OuterJoin
          ).
          on(
              ij_t[:data_source_id].eq(o_at[:data_source_id]).
            and(
              ij_t[:OrganizationID].eq o_at[:OrganizationID]
            )
          ).
          join_sources
        joins(ds_to_v).
        joins(o_to_v).
        joins(p_to_v).
          where.not(
              v_at[:id]. eq(nil).
            and(
              v_at2[:id].eq nil
            ).
            and(
              ij_t[:data_source_id].eq nil
            )
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