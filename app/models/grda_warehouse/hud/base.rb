module GrdaWarehouse::Hud
  class Base < GrdaWarehouseBase
    self.abstract_class = true
    def self.hud_paranoid_column 
      :DateDeleted
    end

    scope :modified_within_range, -> (range:, include_deleted: false) do
      modified_scope = where(
        arel_table[:DateUpdated].gteq(range.first).
        and.arel_table[:DateUpdated].lteq(range.last).
        or(
          arel_table[:DateCreated].gteq(range.first).
          and.arel_table[:DateCreated].lteq(range.last)
        )
      )
      if include_deleted
        modified_scope = modified_scope.or(
          arel_table[:DateDeleted].gteq(range.first).
          and.arel_table[:DateDeleted].lteq(range.last)
        )
      end
      modified_scope
    end

    # an array (in order) of the expected columns for hud CSV data
    def self.hud_csv_headers(version: nil)
      raise NotImplementedError, "#{self.name} needs to implement #hud_csv_headers"
    end

    # Override in sub-classes as necessary
    def self.hud_primary_key
      self.hud_csv_headers.first
    end

    ## convenience methods to DRY up some association definitions

    def self.bipartite_keys(col, model=nil)
      h = { primary_key: [ 'data_source_id', col ], foreign_key: [ 'data_source_id', col ] }
      h.merge! class_name: model.name if model
      h
    end

    def self.hud_assoc(model)
      bipartite_keys model.hud_key, model
    end

    def self.hud_key=(key)
      @hud_key = key
    end

    def self.hud_key
      @hud_key
    end

    ## aliases

    def self.hud_many(model)
      bipartite_keys hud_key, model
    end

    def self.hud_one(model)
      hud_many model
    end

    def self.hud_belongs(model)
      hud_assoc model
    end
  end

end