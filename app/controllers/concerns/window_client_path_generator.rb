###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
