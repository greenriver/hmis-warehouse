require 'net/sftp'

module Health
  class Tasks::ImportEpic
    include TsqlImport
    attr_accessor :send_notifications, :notifier_config

    def initialize
      @notifier_config = Rails.application.config_for(:exception_notifier) rescue nil
      @send_notifications = notifier_config && ( Rails.env.development? || Rails.env.production? )
      if @send_notifications
        @slack_url = @notifier_config['slack']['webhook_url']
        @channel   = @notifier_config['slack']['channel']
        @notifier  = Slack::Notifier.new(
          @slack_url, 
          channel: @channel, 
          username: 'HealthImporter'
        )
        
      end
    end

    def run!
      fetch_files()
      
    end

    def fetch_files
      config = YAML::load(ERB.new(File.read(Rails.root.join("config","health_sftp.yml"))).result)[Rails.env]
      sftp = Net::SFTP.start(config['host'], config['username'], password: config['password']) 
      sftp.download!(config['path'], config['destination'], recursive: true)
      msg = "Health data downloaded"
      Rails.logger.info msg
      @notifier.ping msg
    end
  end
end