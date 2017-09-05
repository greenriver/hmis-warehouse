module WindowClientPathGenerator
  extend ActiveSupport::Concern
  included do
    helper_method :careplan_path_generator
    helper_method :client_path_generator
    helper_method :health_path_generator
    helper_method :file_path_generator
    helper_method :files_path_generator
    helper_method :vispdat_path_generator
    helper_method :vispdats_path_generator
    helper_method :source_client_path_generator

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

    def vispdat_path_generator
      client_path_generator + [:vispdat]
    end

    def vispdats_path_generator
      client_path_generator + [:vispdats]
    end

    def source_client_path_generator
      [:window, :source_client]
    end

    def client_path_generator
      [:window, :client]
    end
  end
end
