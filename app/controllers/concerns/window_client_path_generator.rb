module WindowClientPathGenerator
  extend ActiveSupport::Concern
  included do
    def source_client_path_generator
      [:window, :source_client]
    end
    helper_method :source_client_path_generator

    def client_path_generator
      [:window, :client]
    end
    helper_method :client_path_generator
    
    include CombinedClientPathsGenerator
  end
end
