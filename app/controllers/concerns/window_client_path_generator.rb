module WindowClientPathGenerator
  extend ActiveSupport::Concern
  included do
    helper_method :careplan_path_generator
    helper_method :client_path_generator
    helper_method :health_path_generator

    def careplan_path_generator
      health_path_generator + [:careplan]
    end

    def health_path_generator
      client_path_generator + [:health]
    end

    def client_path_generator
      [:window, :client]
    end
  end
end