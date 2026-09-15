###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SimilarityMetric::Base, type: :model do
  describe '#description' do
    it 'interpolates {{{method}}} placeholders and renders the result as safe markdown' do
      metric_class = Class.new(SimilarityMetric::Base) do
        def comparison_kind
          'exact match'
        end
      end
      metric_class.const_set(:DESCRIPTION, "Uses *{{{comparison_kind}}}* to compare values.\n")

      description = metric_class.new.description

      expect(description).to eq('<p>Uses <em>exact match</em> to compare values.</p>')
      expect(description).to be_html_safe
    end

    it 'escapes HTML returned by an interpolated method instead of rendering it live' do
      metric_class = Class.new(SimilarityMetric::Base) do
        def payload
          '<script>alert(1)</script>'
        end
      end
      metric_class.const_set(:DESCRIPTION, '{{{payload}}}')

      description = metric_class.new.description

      expect(description).to eq('<p>&lt;script&gt;alert(1)&lt;/script&gt;</p>')
      expect(description).not_to include('<script>')
    end

    it 'wraps double-quoted text in <q> tags, matching the prior bare-Redcarpet renderer' do
      metric_class = Class.new(SimilarityMetric::Base)
      metric_class.const_set(:DESCRIPTION, %("Client refused" is one option.\n))

      description = metric_class.new.description

      expect(description).to eq('<p><q>Client refused</q> is one option.</p>')
    end
  end
end
