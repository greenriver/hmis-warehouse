###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour
  module References
    extend ActiveSupport::Concern

    included do
      def initialize(references)
        @references = references
      end

      private def reference(reference_name, &block)
        reference = @references[reference_name]

        if reference[:file].present?
          content = File.read(reference[:file])
          CSV.parse(content, headers: true) do |row|
            block.call(row)
          end
        elsif reference[:model].present?
          reference[:model].find_each do |row|
            block.call(row)
          end
        else
          puts "Unknown reference declaration: #{reference.inspect}"
        end
      end
    end
  end
end
