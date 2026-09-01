###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::Ahar::Fy2017::Base, type: :model do
  describe '#value_for_options' do
    let(:options) do
      {
        'coc_code' => 'XX-500',
        'report_start' => '2016-10-01',
        'report_end' => '2017-09-30',
        'oct_night' => '2016-10-26',
        'jan_night' => '2017-01-25',
        'apr_night' => '2017-04-26',
        'jul_night' => '2017-07-26',
      }
    end

    it 'renders each option under a bold label, joined by line breaks' do
      value = described_class.new.value_for_options(options)

      expect(value).to eq(
        '<strong>CoC Code: </strong>XX-500<br />' \
        '<strong>Start: </strong>2016-10-01<br />' \
        '<strong>End: </strong>2017-09-30<br />' \
        '<strong>Nights: </strong>2016-10-26, 2017-01-25, 2017-04-26, 2017-07-26',
      )
      expect(value).to be_html_safe
    end

    it 'escapes HTML in an option value instead of rendering it live' do
      value = described_class.new.value_for_options(options.merge('coc_code' => '<script>alert(1)</script>'))

      expect(value).to include('<strong>CoC Code: </strong>&lt;script&gt;alert(1)&lt;/script&gt;')
      expect(value).not_to include('<script>alert(1)</script>')
    end
  end
end
