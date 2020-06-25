module HmisCsvTwentyTwenty::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log

      def hmis_data
        slice(*self.class.hmis_structure(version: '2020').keys)
      end
    end
  end
end
