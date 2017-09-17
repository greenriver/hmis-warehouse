module Import::HMISFiveOne::Shared
  extend ActiveSupport::Concern
  included do
    include NotifierConfig

    attr_accessor :file_path

    after_initialize do
      setup_notifier('HMIS Importer 5.1')
    end
    # Provide access to all of the HUD headers with snake case
    # eg: ProjectID is aliased to project_id
    # hud_csv_headers.each do |att|
    #   alias_attribute att.to_s.underscore.to_sym, att
    # end

  end
  
  def log(message)
    @notifier.ping message if @notifier
    logger.info message if @debug
  end

  def hud_csv_headers
    self.class.hud_csv_headers
  end

  class_methods do
    def clean_row_for_import(row)
      row.map do |k,v| 
        [k, v.presence]
      end.to_h.slice(*hud_csv_headers.map(&:to_s))
    end

    def should_add? existing
      existing.to_h.blank?
    end

    def should_restore? row:, existing:
      row['DateUpdated'] == existing.updated_at
    end

    def needs_update? row:, existing:
      row['DateUpdated'] > existing.updated_at
    end

    def delete_involved(projects:, range:, data_source_id:)
      projects.each do |project|
        self.joins(enrollment: :project).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
          update_all(DateDeleted: Time.now)
      end
    end

    # Load up HUD Key and DateUpdated for existing in same data source
    # Loop over incoming, see if the key is there with a newer DateUpdated
    # Update if newer, create if it isn't there, otherwise do nothing
      def import_project_related!(data_source_id:, file_path:)
        import_file_path = "#{file_path}/#{data_source_id}/#{file_name}"
        stats = {
          lines_added: 0, 
          lines_updated: 0, 
        }
        return stats unless File.exists?(import_file_path)
        to_add = []
        headers = nil
        existing_items = self.where(data_source_id: data_source_id).
          pluck(self.hud_key, :DateUpdated, :id).map do |key, updated_at, id|
            [key, OpenStruct.new({updated_at: updated_at, id: id})]
          end.to_h
        CSV.read(
          import_file_path, 
          headers: true
        ).each do |row|
          existing = existing_items[row[self.hud_key.to_s]]
          if should_add?(existing)
            clean_row = clean_row_for_import(row).merge({data_source_id: data_source_id})
            headers ||= clean_row.keys
            to_add << clean_row
          elsif needs_update?(row: row, existing: existing) 
            hud_fields = clean_row_for_import(row)
            self.where(id: existing.id).update_all(hud_fields)
            stats[:lines_updated] += 1
          end
        end
        if to_add.any?
          self.new.insert_batch(self, headers, to_add.map(&:values))
          stats[:lines_added] = to_add.size
        end
        stats
      end

    def import_enrollment_related!(data_source_id:, file_path:)
      import_file_path = "#{file_path}/#{data_source_id}/#{file_name}"
      stats = {
        lines_added: 0, 
        lines_updated: 0, 
      }
      return stats unless File.exists?(import_file_path)
      to_add = []
      to_restore = []
      headers = nil
      existing_items = self.with_deleted.where(data_source_id: data_source_id).
        pluck(self.hud_key, :DateUpdated, :id).map do |key, updated_at, id|
          [key, OpenStruct.new({updated_at: updated_at, id: id})]
        end.to_h

      CSV.read(
        import_file_path, 
        headers: true
      ).each do |row|
        existing = existing_items[row[self.hud_key.to_s]]
        if should_add?(existing)
          clean_row = clean_row_for_import(row).merge({data_source_id: data_source_id})
          headers ||= clean_row.keys
          to_add << clean_row
        elsif should_restore?(row: row, existing: existing)
          to_restore << existing.id
        elsif needs_update?(row: row, existing: existing)
          hud_fields = clean_row_for_import(row)
          self.where(id: existing.id).update_all(hud_fields)
          stats[:lines_updated] += 1
        end
      end
      to_restore.each_slice(1000) do |ids|
        self.where(id: ids).update_all(DateDeleted: nil)
      end
      self.new.insert_batch(self, headers, to_add.map(&:values))
      stats[:lines_added] = to_add.size
      stats
    end

    def hud_csv_headers
      @hud_csv_headers
    end
    
    def setup_hud_column_access(columns)
      @hud_csv_headers = columns
      columns.each do |column|
        alias_attribute(column.to_s.underscore.to_sym, column)
      end
    end

  end
end