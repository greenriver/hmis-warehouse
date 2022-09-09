###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Synthetic
  class YouthEducationStatus < GrdaWarehouseBase
    self.table_name = 'synthetic_youth_education_statuses'

    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :source, polymorphic: true, optional: true
    belongs_to :hud_youth_education_status, class_name: 'GrdaWarehouse::Hud::YouthEducationStatus', optional: true, primary_key: :hud_youth_education_status_youth_education_status_id, foreign_key: :YouthEducationStatusID

    validates_presence_of :enrollment
    validates_presence_of :client

    # Subclasess must define
    #   information_date, data_collection_stage, data_source

    # Subclasses may override
    # The HUD spec allows for nil here, but doesn't define what it would mean -- guessing data not collected
    def current_school_attendance
      99
    end
    alias CurrentSchoolAttend current_school_attendance

    # Should be nil unless current_school_attendance == 0
    def most_recent_educational_status
      nil
    end
    alias MostRecentEdStatus most_recent_educational_status

    # Should be nil unless current_school_attendance.in?([1, 2])
    def current_educational_status
      nil
    end
    alias CurrentEdStatus current_educational_status

    def self.hud_sync
      # Import synthetic events
      GrdaWarehouse::Synthetic.available_youth_education_status_types.each do |class_name|
        class_name.constantize.sync
      end

      create_hud_youth_education_statuses

      # Clean up orphans in HUD table
      GrdaWarehouse::Hud::YouthEducationStatus.
        where(synthetic: true).
        where.not(YouthEducationStatusID: select(:hud_youth_education_status_youth_education_status_id)).
        delete_all
    end

    def self.create_hud_youth_education_statuses
      preload(:enrollment, :client, :source).find_in_batches do |batch|
        to_import = batch.map(&:hud_youth_education_status_hash)
        youth_education_status_source.import(
          to_import.compact,
          on_duplicate_key_update: {
            conflict_target: ['"YouthEducationStatusID"', :data_source_id],
            columns: youth_education_status_source.hmis_configuration(version: '2022').keys,
          },
        )
        batch.each.with_index do |synthetic, i|
          added = to_import[i]
          next if added.blank?

          synthetic.update(hud_youth_education_status_youth_education_status_id: added[:YouthEducationStatusID])
        end
      end
    end

    def hud_youth_education_status_hash
      return nil unless enrollment.present? &&
        source.present?

      unique_key = [enrollment.EnrollmentID, enrollment.PersonalID, information_date, enrollment.data_source_id, source.id]
      youth_education_status_id = hud_youth_education_status&.YouthEducationStatusID || Digest::MD5.hexdigest(unique_key.join('_'))
      {
        AssessmentID: youth_education_status_id,
        EnrollmentID: enrollment.EnrollmentID,
        PersonalID: enrollment.PersonalID,
        InformationDate: information_date,
        CurrentSchoolAttend: current_school_attendance || 99,
        MostRecentEdStatus: most_recent_educational_status,
        CurrentEdStatus: current_educational_status,
        DataCollectionStage: data_collection_stage,
        DateCreated: source.created_at,
        DateUpdated: source.updated_at,
        UserID: user_id,
        data_source_id: enrollment.data_source_id,
        synthetic: true,
      }
    end

    private def user_id
      @user_id ||= User.setup_system_user.name
    end

    def self.youth_education_status_source
      GrdaWarehouse::Hud::YouthEducationStatus
    end
  end
end
