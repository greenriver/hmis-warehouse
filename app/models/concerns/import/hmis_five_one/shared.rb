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
      existing.blank?
    end

    def needs_update? row:, existing:
      row['DateUpdated'] > existing.updated_at
    end

    def delete_involved(projects:, range:, data_source_id:)
      projects.each do |project|
        self.joins(:project, :enrollment).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
          update_all(DateDeleted: Time.now)
      end
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