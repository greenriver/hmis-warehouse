###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaData
  class Assessment < GrdaWarehouseBase
    include Shared
    self.table_name = :eccovia_assessments
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
    acts_as_paranoid

    def self.fetch_updated(data_source_id:, credentials:)
      since = max_fetch_time || default_lookback

      query = "crql?q=select VulnerabilityID, ClientID, CreatedBy, UpdatedDate from VulnerabilityIndex where UpdatedDate > '#{since.to_s(:db)}'"
      credentials.get_all_in_batches(query) do |assessment_batch|
        break unless assessment_batch.present?

        assessments = assessment_batch.index_by { |a| a['VulnerabilityID'] }

        scores(assessments.keys, credentials: credentials).each do |score|
          assessments[score['VulnerabilityID']]['ScoreTotal'] = score['ScoreTotal']
        end

        user_objects = users(assessments.values.map { |a| a['CreatedBy'] }.uniq, credentials: credentials).index_by { |u| u['UserID'] }

        batch = assessments.values.map do |assessment|
          user = user_objects[assessment['UserID']]
          new(
            data_source_id: data_source_id,
            client_id: assessment['ClientID'],
            assessment_id: assessment['VulnerabilityID'],
            score: assessment['ScoreTotal'],
            assessed_at: assessment['UpdatedDate'],
            assessor_id: assessment['CreatedBy'],
            assessor_email: user.try(:[], 'Email'),
            last_fetched_at: Time.current,
          )
        end

        import(
          batch,
          on_duplicate_key_update: {
            conflict_target: [:client_id, :data_source_id, :assessment_id],
            columns: [
              :score,
              :assessed_at,
              :assessor_id,
              :assessor_email,
              :last_fetched_at,
            ],
          },
          validate: false,
        )
      end
      remove_deleted(data_source_id: data_source_id, credentials: credentials)
    end

    def self.remove_deleted(data_source_id:, credentials:)
      where(data_source_id: data_source_id).where.not(assessment_id: all_assessment_ids(credentials: credentials)).destroy_all
    end

    def self.all_assessment_ids(credentials:)
      query = 'crql?q=select VulnerabilityID from VulnerabilityIndex'
      credentials.get_all(query)&.map { |a| a['VulnerabilityID'] }
    end

    def self.scores(ids, credentials:)
      query = "crql?q=SELECT ScoreTotal, VulnerabilityID FROM VISPDAT where VulnerabilityID in (#{quote(ids)})"
      credentials.get_all(query)
    end
  end
end
