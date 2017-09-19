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
      row = row.map do |k,v| 
        [k, v.presence]
      end.to_h.slice(*hud_csv_headers.map(&:to_s))
      # the batch import fails to correctly guess the timezone, force these into useful times
      row['DateUpdated'] = row['DateUpdated'].to_time
      row['DateCreated'] = row['DateCreated'].to_time
      row['DateDeleted'] = row['DateDeleted']&.to_time
      row
    end

    def should_add? existing
      existing.to_h.blank?
    end

    def should_restore? row:, existing:, soft_delete_time:
      soft_deleted_this_time = existing.deleted_at.present? && existing.deleted_at == soft_delete_time
      exists_in_incoming_file = row['DateDeleted'].blank?
      deleted_previously = existing.deleted_at.present? && existing.deleted_at != soft_delete_time
      incoming_is_newer = row['DateUpdated'].to_time > existing.updated_at
      soft_deleted_this_time && exists_in_incoming_file || deleted_previously && incoming_is_newer
    end

    def needs_update? row:, existing:
      row['DateUpdated'].to_time > existing.updated_at
    end

    def delete_involved(projects:, range:, data_source_id:, deleted_at:)
      deleted_count = 0
      projects.each do |project|
        deleted_count += self.joins(enrollment: :project).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
          update_all(DateDeleted: deleted_at)
      end
      deleted_count
    end

    # Load up HUD Key and DateUpdated for existing in same data source
    # Loop over incoming, see if the key is there with a newer DateUpdated
    # Update if newer, create if it isn't there, otherwise do nothing
      def import_project_related!(data_source_id:, file_path:, stats:)
        import_file_path = "#{file_path}/#{data_source_id}/#{file_name}"
        stats[:errors] = []
        return stats unless File.exists?(import_file_path)
        to_add = []
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
          elsif needs_update?(row: row, existing: existing) 
            hud_fields = clean_row_for_import(row)
            self.with_deleted.where(id: existing.id).update_all(hud_fields)
            stats[:lines_updated] += 1
          end
        end
        if to_add.any?
          to_add = clean_to_add(to_add)
          stats = process_to_add(headers: headers, to_add: to_add, stats: stats)
        end
        stats
      end

    def import_enrollment_related!(data_source_id:, file_path:, stats:, soft_delete_time:)
      import_file_path = "#{file_path}/#{data_source_id}/#{file_name}"
      stats[:errors] = []
      return stats unless File.exists?(import_file_path)
      to_add = []
      to_restore = []
      headers = nil
      existing_items = self.with_deleted.where(data_source_id: data_source_id).
        pluck(self.hud_key, :DateUpdated, :DateDeleted, :id).map do |key, updated_at, deleted_at, id|
          [key, OpenStruct.new({updated_at: updated_at, deleted_at: deleted_at, id: id})]
        end.to_h
      export_id = nil
      CSV.read(
        import_file_path, 
        headers: true
      ).each do |row|
        export_id ||= row['ExportID']
        existing = existing_items[row[self.hud_key.to_s]]
  
        if should_add?(existing)
          clean_row = clean_row_for_import(row).merge({data_source_id: data_source_id})
          headers ||= clean_row.keys
          to_add << clean_row
        elsif needs_update?(row: row, existing: existing)
          hud_fields = clean_row_for_import(row)
          self.with_deleted.where(id: existing.id).update_all(hud_fields)
          stats[:lines_updated] += 1
          stats[:lines_restored] += 1 if existing.deleted_at.present? && row['DateDeleted'].blank?
        elsif should_restore?(row: row, existing: existing, soft_delete_time: soft_delete_time)
          to_restore << existing.id
        end
      end
      to_restore.each_slice(1000) do |ids|
        # Make sure to update the export id when restoring to help with service history
        # generation
        self.with_deleted.where(id: ids).update_all(DateDeleted: nil, ExportID: export_id)
        stats[:lines_restored] += ids.size
      end
      if to_add.any?
        to_add = clean_to_add(to_add)
        stats = process_to_add(headers: headers, to_add: to_add, stats: stats)
      end
      stats
    end

    def process_to_add headers:, to_add:, stats:
      to_add.each_slice(200) do |batch|
        begin
          self.new.insert_batch(self, headers, batch.map(&:values), transaction: false)
          stats[:lines_added] += batch.size
        rescue Exception => exception
          message = "Failed to add batch for #{self.name}, attempting individual inserts"
          stats[:errors] << {message: message, line: ''}
          Rails.logger.warn(message)
          # Try again to add the individual batch
          batch.each do |row|
            begin
              self.create(row)
            rescue Exception => e
              message = "Failed to add #{self.name}: #{exception.message}; giving up on this one."
              stats[:errors] << {message: message, line: row.inspect}
              Rails.logger.warn(message)
            end
          end
        end
      end
      stats
    end

    def clean_to_add to_add
      # Remove any duplicates that would violate the unique key constraints
      to_add.index_by{|row| row.values_at(*self.unique_constraint.map(&:to_s))}.values
    end

    # Override in sub-classes
    def unique_constraint
      [self.hud_key, :data_source_id]
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