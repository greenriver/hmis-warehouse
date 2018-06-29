module GrdaWarehouse::Import::HMISSixOneOne
  class Project < GrdaWarehouse::Hud::Project
    include ::Import::HMISSixOneOne::Shared
    self.hud_key = :ProjectID
    setup_hud_column_access( GrdaWarehouse::Hud::Project.hud_csv_headers(version: '6.11') )

    attr_accessor :existing

    def import!
      return if existing_is_newer()
      if existing.to_h.present?
        # update any of the hud values coming from the import
        self.class.with_deleted.where(id: existing.id).update_all(attributes.slice(*hud_csv_headers.map(&:to_s)))
      else
        save
      end
    end

    # Determine if the project type has changed and update
    # any service history records involving this project
    def update_changed_project_types
      return if existing.blank?
      return if project_type_unchanged()
      return if existing_is_newer()
      log("Updating Service Histories for #{project_name}, project type has changed")
      GrdaWarehouse::ServiceHistoryEnrollment.where(
        data_source_id: data_source_id,
        project_id: project_id,
        organization_id: organization_id
      ).
      update_all(
        project_name: project_name,
        organization_id: organization_id,
        project_type: project_type,
        project_tracking_method: tracking_method
      )
    end

    def existing_is_newer
      existing.to_h.present? && existing.updated_at >= date_updated
    end

    def project_type_unchanged
      existing.project_type == project_type
    end

    def self.load_from_csv(file_path: , data_source_id: )
      existing_projects = self.with_deleted.where(data_source_id: data_source_id).pluck(self.hud_key, :DateUpdated, :ProjectType, :id).map do |key, updated_at, project_type, id|
        [key, {updated_at: updated_at, project_type: project_type, id: id}]
      end.to_h
      [].tap do |m|
        CSV.read(
          "#{file_path}/#{data_source_id}/#{file_name}",
          headers: true
        ).each do |row|
          extra = {
            file_path: file_path,
            data_source_id: data_source_id,
            existing: OpenStruct.new(existing_projects[row[self.hud_key.to_s]]),
          }
          m << new(row.to_h.merge(extra))
        end
      end
    end

    def self.file_name
      'Project.csv'
    end

  end
end