module GrdaWarehouse::Tasks
  class UpdateClientsFromHmisForms
    include NotifierConfig
    attr_accessor :logger, :send_notifications, :notifier_config
    def initialize(client_ids: [])
      setup_notifier('HMIS Form -> Client Sync')
      self.logger = Rails.logger
      @client_ids = client_ids
    end

    def run!
      # Fail gracefully if there's no ETO API
      return unless GrdaWarehouse::Config.get(:eto_api_available)
      @notifier.ping('Updating clients from HMIS Forms...') if @send_notifications
      update_rrh_assessment_data()
      @notifier.ping('Updated clients from HMIS Forms') if @send_notifications
    end

    def update_rrh_assessment_data
      clients = clients_with_rrh_assessments
      clients.each do |client|
        assessment = most_recent_rrh_assessment(client)
        client.rrh_assessment_score = assessment.rrh_assessment_score
        client.rrh_assessment_collected_at = assessment.collected_at
        client.ssvf_eligible = assessment.veteran_score.present?
        client.rrh_desired = assessment.rrh_desired?
        client.youth_rrh_desired = assessment.youth_rrh_desired?
        client.rrh_assessment_contact_info = assessment.rrh_contact_info
        client.save
      end
    end

    def clients_with_rrh_assessments
      client_scope.joins(:source_hmis_forms).
        merge(GrdaWarehouse::HmisForm.rrh_assessment).distinct
    end

    def client_scope
      if @client_ids.any?
        GrdaWarehouse::Hud::Client.where(id: @client_ids)
      else
        GrdaWarehouse::Hud::Client
      end
    end

    def most_recent_rrh_assessment(client)
      client.source_hmis_forms.rrh_assessment.newest_first.limit(1).first
    end
  end
end
