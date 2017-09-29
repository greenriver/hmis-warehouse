module Exporters::HmisSixOneOne
  class Base
    include NotifierConfig
    
    attr_accessor :logger, :notifier_config

    def initialize(
      file_path: 'var/hmis_export',
      logger: Rails.logger, 
      debug: true,
      range:,
      projects:,
      period_type:,
      directive:,
      hash_status:
    )
      setup_notifier('HMIS Exporter 6.11')
      @file_path = file_path
      @logger = logger
      @debug = debug
      @range = range
      @projects = projects
      @period_type = period_type
      @directive = directive
      @hash_status = hash_status     
      
    end

    def export!
      
    end

    def log(message)
      @notifier.ping message if @notifier
      logger.info message if @debug
    end
  end
end