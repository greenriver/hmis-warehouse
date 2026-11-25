###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropImporterPendingDeletionIndexes < ActiveRecord::Migration[8.1]
  # Staging and production drop these indexes concurrently, outside the deploy, via the
  # :drop_importer_pending_deletion_indexes TaskQueue task
  # (GrdaWarehouse::Tasks::DropImporterPendingDeletionIndexes). Keep the definitions in sync.
  PENDING_DATE_DELETED_INDEXES = [
    { table: :ClientUnencrypted, name: 'ClientUnencrypted_pending_date_deleted_idx' },
    { table: :Affiliation, name: 'index_Affiliation_on_pending_date_deleted' },
    { table: :AssessmentQuestions, name: 'index_AssessmentQuestions_on_pending_date_deleted' },
    { table: :AssessmentResults, name: 'index_AssessmentResults_on_pending_date_deleted' },
    { table: :Assessment, name: 'index_Assessment_on_pending_date_deleted' },
    { table: :Client, name: 'index_Client_on_pending_date_deleted' },
    { table: :CurrentLivingSituation, name: 'index_CurrentLivingSituation_on_pending_date_deleted' },
    { table: :Disabilities, name: 'index_Disabilities_on_pending_date_deleted' },
    { table: :EmploymentEducation, name: 'index_EmploymentEducation_on_pending_date_deleted' },
    { table: :EnrollmentCoC, name: 'index_EnrollmentCoC_on_pending_date_deleted' },
    { table: :Enrollment, name: 'index_Enrollment_on_pending_date_deleted' },
    { table: :Event, name: 'index_Event_on_pending_date_deleted' },
    { table: :Exit, name: 'index_Exit_on_pending_date_deleted' },
    { table: :Funder, name: 'index_Funder_on_pending_date_deleted' },
    { table: :Geography, name: 'index_Geography_on_pending_date_deleted' },
    { table: :HealthAndDV, name: 'index_HealthAndDV_on_pending_date_deleted' },
    { table: :IncomeBenefits, name: 'index_IncomeBenefits_on_pending_date_deleted' },
    { table: :Inventory, name: 'index_Inventory_on_pending_date_deleted' },
    { table: :Organization, name: 'index_Organization_on_pending_date_deleted' },
    { table: :ProjectCoC, name: 'index_ProjectCoC_on_pending_date_deleted' },
    { table: :Project, name: 'index_Project_on_pending_date_deleted' },
    { table: :Services, name: 'index_Services_on_pending_date_deleted' },
    { table: :User, name: 'index_User_on_pending_date_deleted' },
  ].freeze

  def up
    return unless Rails.env.local?

    safety_assured do
      PENDING_DATE_DELETED_INDEXES.each do |index|
        remove_index(index[:table], name: index[:name], if_exists: true)
      end
      remove_index(:Enrollment, name: 'Enrollment_634d', if_exists: true)
    end
  end

  def down
    return unless Rails.env.local?

    safety_assured do
      PENDING_DATE_DELETED_INDEXES.each do |index|
        add_index(index[:table], :pending_date_deleted, name: index[:name], if_not_exists: true)
      end
      add_index(:Enrollment, :ExportID, name: 'Enrollment_634d', if_not_exists: true)
    end
  end
end
