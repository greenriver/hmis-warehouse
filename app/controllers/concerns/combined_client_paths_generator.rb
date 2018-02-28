module CombinedClientPathsGenerator
  extend ActiveSupport::Concern
  included do
    def careplan_path_generator
      health_path_generator + [:careplan]
    end
    helper_method :careplan_path_generator

    def health_path_generator
      client_path_generator + [:health]
    end
    helper_method :health_path_generator

    def history_path_generator
      client_path_generator + [:history]
    end
    helper_method :history_path_generator

    def users_path_generator
      client_path_generator + [:users]
    end
    helper_method :users_path_generator

    def user_path_generator
      client_path_generator + [:user]
    end
    helper_method :user_path_generator

    def month_of_service_path_generator
      client_path_generator + [:month_of_service]
    end
    helper_method :month_of_service_path_generator

    def file_path_generator
      client_path_generator + [:file]
    end
    helper_method :file_path_generator 

    def files_path_generator
      client_path_generator + [:files]
    end
    helper_method :files_path_generator    

    def files_batch_download_path_generator
      [:batch_download] + files_path_generator
    end
    helper_method :files_batch_download_path_generator

    def vispdat_path_generator
      client_path_generator + [:vispdat]
    end
    helper_method :vispdat_path_generator

    def vispdats_path_generator
      client_path_generator + [:vispdats]
    end
    helper_method :vispdats_path_generator

    def edit_cas_readiness_path_generator
      [:edit] + client_path_generator + [:cas_readiness]
    end
    helper_method :edit_cas_readiness_path_generator

    def cas_readiness_path_generator
      client_path_generator + [:cas_readiness]
    end
    helper_method :cas_readiness_path_generator

    def client_note_path_generator
      client_path_generator + [:note]
    end
    helper_method :client_note_path_generator 

    def client_notes_path_generator
      client_path_generator + [:notes]
    end
    helper_method :client_notes_path_generator

    def client_chronic_path_generator
      [:edit] + client_path_generator + [:chronic]
    end
    helper_method :client_chronic_path_generator

    def source_client_image_path_generator
      [:image] + source_client_path_generator
    end
    helper_method :source_client_image_path_generator
  end
end
