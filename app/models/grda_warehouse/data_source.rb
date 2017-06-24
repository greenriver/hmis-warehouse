class GrdaWarehouse::DataSource < GrdaWarehouseBase
  validates :name, presence: true
  validates :short_name, presence: true

  has_many :import_logs
  has_many :services, class_name: GrdaWarehouse::Hud::Service.name, inverse_of: :data_source
  has_many :enrollments, class_name: GrdaWarehouse::Hud::Enrollment.name, inverse_of: :data_source
  has_many :exits, class_name: GrdaWarehouse::Hud::Exit.name, inverse_of: :data_source
  has_many :clients, class_name: GrdaWarehouse::Hud::Client.name, inverse_of: :data_source
  has_many :organizations, class_name: GrdaWarehouse::Hud::Organization.name, inverse_of: :data_source
  has_many :projects, class_name: GrdaWarehouse::Hud::Project.name, inverse_of: :data_source
  has_many :exports, class_name: GrdaWarehouse::Hud::Export.name, inverse_of: :data_source
  has_many :user_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::Hud::UserViewableEntity'

  scope :importable, -> { where.not(source_type: nil)}
  scope :destination, -> { where(source_type: nil)}
  scope :importable_via_samba, -> { importable.where(source_type: "samba")}
  scope :viewable_by, -> (user) do
    if user.roles.where( can_view_everything: true ).exists?
      current_scope
    else
      # unfortunately an arel bug prevented our using a much simpler query using existence subqueries
      ds_at = arel_table
      v_at  = Arel::Table.new GrdaWarehouse::Hud::UserViewableEntity.table_name
      v_at2 = Arel::Table.new v_at.table_name
      v_at3 = Arel::Table.new v_at.table_name
      p_at  = Arel::Table.new GrdaWarehouse::Hud::Project.table_name
      o_at  = Arel::Table.new GrdaWarehouse::Hud::Organization.table_name
      ij1_t = Arel::Table.new 'ij1_t'
      ij2_t = Arel::Table.new 'ij2_t'
      # add some aliases to make this more composable
      pfx = "ds_vb_"
      v_at.table_alias   = "#{pfx}_v_at"
      v_at2.table_alias  = "#{pfx}_v_at2"
      v_at3.table_alias  = "#{pfx}_v_at3"
      p_at.table_alias   = "#{pfx}_p_at"
      o_at.table_alias   = "#{pfx}_o_at"
      ds_to_v = ds_at.join( v_at, Arel::Nodes::OuterJoin ).
        on(
            v_at[:entity_type].eq(sti_name).
          and(
            v_at[:entity_id].  eq ds_at[:id]
          ).
          and(
            v_at[:user_id].    eq user.id
          )
        ).
        join_sources
      o_to_v = o_at.join( 
          v_at2.join(o_at).
            project(o_at[:data_source_id]).
            on(
                v_at2[:entity_type].eq(GrdaWarehouse::Hud::Organization.sti_name).
              and(
                v_at2[:user_id].    eq user.id
              ).
              and(
                o_at[:DateDeleted]. not_eq nil
              )
            ).
            as(ij1_t.table_name),
          Arel::Nodes::OuterJoin
        ).
        on(
          ij1_t[:data_source_id].eq ds_at[:id]
        ).
        join_sources
      p_to_v = p_at.join( 
          v_at3.join(p_at).
            project(p_at[:data_source_id]).
            on(
                v_at3[:entity_type].eq(GrdaWarehouse::Hud::Project.sti_name).
              and(
                v_at3[:user_id].    eq user.id
              ).
              and(
                p_at[:DateDeleted]. not_eq nil
              )
            ).
            as(ij2_t.table_name),
          Arel::Nodes::OuterJoin
        ).
        on(
          ij2_t[:data_source_id].eq ds_at[:id]
        ).
        join_sources
      joins(ds_to_v).
      joins(o_to_v).
      joins(p_to_v).
        where.not(
            v_at[:id]. eq(nil).
          and(
            ij1_t[:data_source_id].eq nil
          ).
          and(
            ij2_t[:data_source_id].eq nil
          )
        )
    end
  end

  accepts_nested_attributes_for :projects

  def self.names
    importable.select(:id, :short_name).distinct.pluck(:short_name, :id)
  end

  def self.short_name id
    @short_names ||= importable.select(:id, :short_name).distinct.pluck(:id, :short_name).to_h
    @short_names[id]
  end

  def self.text_search(text)
    return none unless text.present?

    query = "%#{text}%"
    where(
      arel_table[:name].matches(query)
    )
  end

  # caculate the data coverage dates available for each data source
  # FIXME: this is a huge table scan across several tables so it
  # would be nice if the importers could maintain these dates somewhere
  def self.data_spans_by_id
    spans_by_id = {}
    dates_to_check = {
      GrdaWarehouse::Hud::Enrollment => 'EntryDate',
      GrdaWarehouse::Hud::Service => 'DateProvided',
      GrdaWarehouse::Hud::Exit => 'ExitDate'
    }
    dates_to_check.each do |model, field|
      # logger.debug "#{model}, #{field} #{model.count}"
      # idxes = model.connection.indexes(model.table_name).map{|i| [i.name] + i.columns}
      # logger.debug "indexes: #{idxes}"
      # logger.debug scope.explain
      scope = model.where(
        data_source_id: pluck(:id)
      ).group(
        :data_source_id
      ).select(
        "data_source_id, min(#{model.connection.quote_column_name(field)}), max(#{model.connection.quote_column_name(field)})"
      )
      model.connection.select_rows(scope.to_sql).each do |id, min, max|
        spans_by_id[id] ||= [nil, nil]
        spans_by_id[id][0] = min if spans_by_id[id][0].nil? || min < spans_by_id[id][0]
        spans_by_id[id][1] = max if spans_by_id[id][1].nil? || max > spans_by_id[id][1]
      end
    end
    spans_by_id
  end

  def data_span
    return unless enrollments.any?
    if self.id.present?
      self.class.where(id: self.id).data_spans_by_id[self.id]
    end
  end

  def manual_import_path
    "/tmp/uploaded#{file_path}"
  end

  def has_data?
    exports.any?
  end
end