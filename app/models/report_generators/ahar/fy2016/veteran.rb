# Notes: see https://www.pivotaltracker.com/file_attachments/68760691/download for spec
# For each of the SUB_TYPES we need to answer the GLOBAL_QUESTIONS and the specific questions.
# In addition, we need to answer the summary questions as their own category
# 
# In Rails console: 
# load '/Users/elliot/Sites/boston-hmis/app/models/report_generators/ahar/fy2016/ahar.rb'
# answers = ReportGenerators::Ahar::Fy2016::Veteran.new.run!

# Definitions
# LTS: Long Term Stayers - 180 days within report range
# 
# HMIS terms
# http://www.hudhdx.info/Resources/Vendors/4_0/docs/HUD_HMIS_xsd.html
# 
# This is the veteran only version of the AHAR report, we'll override all queries that 
# bring in client information to limit them to veterans only
module ReportGenerators::Ahar::Fy2016
  class Veteran < Base
    def report_class
      Reports::Ahar::Fy2016::Veteran
    end

    def vets_only
      true
    end

    def involved_entries_scope
      # super.joins(:client).where(client: {VeteranStatus: 1})
      
      # This doesn't include people who are in the family with a Vet, so we need to 
      # expand our search with the following ugly query
      # In addition, we're plucking and filtering to client ids because the 
      # full query is too expensive for the database
      @involved_entries_scope ||= super.where(
        client_id: vet_or_related_client_ids(scope: super)
      )
    end

    def vet_or_related_client_ids(scope:)
      vet_ids = scope.joins(:client).where(client: {VeteranStatus: 1}).
        select(:client_id, :VeteranStatus, 'concat(warehouse_client_service_history.household_id, \'__\', warehouse_client_service_history.data_source_id, \'__\', warehouse_client_service_history.project_id)').
        where(record_type: 'entry').
        distinct.
        pluck(:client_id, :VeteranStatus, 'concat(warehouse_client_service_history.household_id, \'__\', warehouse_client_service_history.data_source_id, \'__\', warehouse_client_service_history.project_id)')
      # filter out anyone with a nil household_id when looking for related
      # folks since that implies an individual (which we should have in the vet_ids above)
      original = scope.joins(:client).
        where(client: {VeteranStatus: 1}).
        where.not(household_id: nil).
        where.not(household_id: '').
        select("concat(warehouse_client_service_history.household_id, '__', warehouse_client_service_history.data_source_id, '__', warehouse_client_service_history.project_id)")
      related_ids = scope.
        joins(:client).
        where(['concat(warehouse_client_service_history.household_id, \'__\', warehouse_client_service_history.data_source_id, \'__\', warehouse_client_service_history.project_id) in (?)', original]).
        where(record_type: 'entry').
        select(:client_id, :VeteranStatus, 'concat(warehouse_client_service_history.household_id, \'__\', warehouse_client_service_history.data_source_id, \'__\', warehouse_client_service_history.project_id)').
        distinct.
        pluck(:client_id, :VeteranStatus, 'concat(warehouse_client_service_history.household_id, \'__\', warehouse_client_service_history.data_source_id, \'__\', warehouse_client_service_history.project_id)')
      # Return only the client_ids (we've selected some other bits for verification)
      (vet_ids + related_ids).uniq.map(&:first)
    end
  end
end