namespace :log do
  
  desc "Log INFO and DEBUG to STDOUT"
  task :debug_to_stdout => [:environment] do
    if Rails.env == "development"
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      Rails.logger = logger
    end
  end

  desc "Log INFO to STDOUT"
  task :info_to_stdout => [:environment] do
    if Rails.env == "development"
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO
      Rails.logger = logger
    end
  end
end


