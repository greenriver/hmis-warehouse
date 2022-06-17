###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class HMIS::Eccovia::Assessment < GrdaWarehouseBase
    self.table_name = :eccovia_assessments
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: [:client_id, :data_source_id], primary_key: [:PersonalID, :data_source_id]
    acts_as_paranoid

    def self.fetch_updated(data_source_id:, credentials:, since:)
      since ||= 3.years.ago

      query = "crql?q=select VulnerabilityID, ClientID, CreatedBy, UpdatedDate from VulnerabilityIndex where UpdatedDate > '#{since.to_s(:db)}'"
      assessments = credentials.get_all(query).index_by { |a| a['VulnerabilityID'] }
      return unless assessments.present?

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
          columns: [:score, :assessed_at, :assessor_id, :assessor_email, :last_fetched_at],
        },
        validate: false,
      )
    end

    def self.scores(ids, credentials:)
      query = "crql?q=SELECT ScoreTotal, VulnerabilityID FROM VISPDAT where VulnerabilityID in (#{quote(ids)})"
      credentials.get_all(query)
    end

    def self.users(ids, credentials:)
      query = "crql?q=SELECT UserID, CellPhone, OfficePhone, Email FROM osUsers where UserID in (#{quote(ids)})"
      credentials.get_all(query)
    end

    def self.quote(ids)
      ids.map { |id| connection.quote(id) }.join(', ')
    end
  end
end
