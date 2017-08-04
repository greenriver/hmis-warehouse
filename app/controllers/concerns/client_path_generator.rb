module ClientPathGenerator
  extend ActiveSupport::Concern
  included do
    helper_method :careplan_path_generator
    helper_method :client_path_generator
    helper_method :health_path_generator
    helper_method :file_path_generator
    helper_method :files_path_generator

    def careplan_path_generator
      health_path_generator + [:careplan]
    end

    def health_path_generator
      client_path_generator + [:health]
    end
    
    def file_path_generator
      client_path_generator + [:file]
    end
    
    def files_path_generator
      client_path_generator + [:files]
    end
    
    def client_path_generator
      [:client]
    end
  end
end
