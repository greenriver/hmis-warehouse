module GrdaWarehouse::Import::HMISFiveOne
  class Project < GrdaWarehouse::Hud::Project
    include ::Import::HMISFiveOne::Shared

    setup_hud_column_access( 
      [
        :ProjectID,
        :OrganizationID,
        :ProjectName,
        :ProjectCommonName,
        :ContinuumProject,
        :ProjectType,
        :ResidentialAffiliation,
        :TrackingMethod,
        :TargetPopulation,
        :PITCount,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID
      ]
    )
    
    def import!
      look_for_existing()
      return if existing_is_newer()
      if @existing.present?
        # update any of the hud values coming from the import
        @existing.update_attributes(attributes.slice(*hud_csv_headers.map(&:to_s)))
      else
        save
      end
    end

    # Determine if the project type has changed and update
    # any service history records involving this project
    def update_changed_project_types
      look_for_existing()
      return if @existing.blank?
      return if project_type_unchanged()
      return if existing_is_newer()
      log("Updating Service Histories for #{project_name}, project type has changed")
      GrdaWarehouse::ServiceHistory.where(
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
      look_for_existing()
      @existing.date_updated > date_updated
    end

    def project_type_unchanged
      look_for_existing()
      @existing.project_type == project_type
    end

    def look_for_existing
      @existing ||= self.class.find_by(ProjectID: project_id, data_source_id: data_source_id)
    end
    
    def self.load_from_csv(file_path: , data_source_id: )
      [].tap do |m|
        CSV.read(
          "#{file_path}/#{data_source_id}/#{file_name}", 
          headers: true
        ).each do |row|
          m << new(row.to_h.merge({file_path: file_path, data_source_id: data_source_id}))
        end
      end
    end

    def self.file_name
      'Project.csv'
    end

  end
end