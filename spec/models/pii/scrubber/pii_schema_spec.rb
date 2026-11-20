###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Declared PII attributes must be scrubbable: a real column, nullable unless the
# scrubber has a placeholder for it.
RSpec.describe 'PII attribute declarations' do
  it 'can be scrubbed on every model the scrub task visits' do
    violations = Pii::Scrubber::ScrubbableModels.all.flat_map do |model|
      model.pii_attributes_config.values.filter_map do |config|
        next if config[:type] == :attached_file

        column = model.columns_hash[config[:name].to_s]
        label = "#{model.name}##{config[:name]}"
        if column.nil?
          "#{label} is not a column"
        elsif config[:level] < 3 && !config[:required] && !column.null
          "#{label} is sensitive, optional and on a NOT NULL column"
        elsif config[:required] && !(Pii::Scrubber::ReplacementPii::STATIC_TYPE_VALUES.key?(config[:type]) || config[:type] == :dob)
          "#{label} is required but has no placeholder for type #{config[:type]}"
        end
      end
    end

    expect(violations).to eq([])
  end
end
