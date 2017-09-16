module GrdaWarehouse::Import::HMISFiveOne
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :OrganizationID,
        :OrganizationName,
        :OrganizationCommonName,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :OrganizationID
    
    # Load up HUD Key and DateUpdated for existing in same data source
    # Loop over incoming, see if the key is there with a newer DateUpdated
    # Update if newer, create if it isn't there, otherwise do nothing
    def self.import!(data_source_id:, file_path:)
      stats = {
        lines_added: 0, 
        lines_updated: 0, 
      }
      to_add = []
      existing_organizations = self.where(data_source_id: data_source_id).
        pluck(self.hud_key, :DateUpdated, :id).map do |key, updated_at, id|
          [key, OpenStruct.new({updated_at: updated_at, id: id})]
        end.to_h

      CSV.read(
        "#{file_path}/#{data_source_id}/#{file_name}", 
        headers: true
      ).each do |row|
        existing = existing_organizations[row[self.hud_key.to_s]]
        if should_add?(existing) 
          to_add << row.map do |k,v| 
            [k, v.presence]
          end.to_h.slice(*hud_csv_headers.map(&:to_s)).
            merge({data_source_id: data_source_id})
        elsif needs_update?(row: row, existing: existing) 
          hud_fields = row.map do |k,v| 
            [k, v.presence]
          end.to_h.slice(*hud_csv_headers.map(&:to_s))
          self.where(id: existing.id).update_all(hud_fields)
          stats[:lines_updated] += 1
        end
      end
      headers = hud_csv_headers + [:data_source_id]
      self.new.insert_batch(self, headers, to_add.map(&:values))
      stats[:lines_added] = to_add.size
      stats
    end

    def self.should_add? existing
      existing.blank?
    end

    def self.needs_update? row:, existing:
      row['DateUpdated'] > existing.updated_at
    end

    def self.file_name
      'Organization.csv'
    end
  end
end