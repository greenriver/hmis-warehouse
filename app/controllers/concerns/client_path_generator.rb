
module ClientPathGenerator
  extend ActiveSupport::Concern
  included do
    def source_client_path_generator
      [:source_client]
    end
    helper_method :source_client_path_generator

    def client_path_generator
      [:client]
    end
    helper_method :client_path_generator
  end
  
  include CombinedClientPathsGenerator
end
