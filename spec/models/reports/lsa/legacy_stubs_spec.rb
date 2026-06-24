###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports::Lsa legacy FY stubs', type: :model do
  # shared_examples defines a reusable block of examples under a name.
  shared_examples 'an LSA legacy FY stub' do |all_class:, base_class:, report_name:|
    describe all_class do
      describe 'class hierarchy' do
        it 'is a subclass of Report' do
          expect(all_class.ancestors).to include(Report)
        end

        it 'has a Base class that is also a subclass of Report' do
          expect(base_class.ancestors).to include(Report)
        end

        it 'All inherits from Base' do
          expect(all_class.ancestors).to include(base_class)
        end
      end

      describe '.report_name' do
        it "returns '#{report_name}'" do
          expect(base_class.report_name).to eq(report_name)
        end
      end

      describe '#report_group_name' do
        it "returns 'Longitudinal System Analysis '" do
          expect(all_class.new.report_group_name).to eq('Longitudinal System Analysis ')
        end
      end

      describe 'STI round-trip' do
        it 'is instantiated as the concrete class when loaded through Report' do
          record = Report.create!(type: all_class.name, name: "#{report_name} test")
          found = Report.find(record.id)
          expect(found.class).to eq(all_class)
        end
      end
    end
  end

  # include_examples runs the shared block inline here, once per call, with
  # different arguments. Each call produces a full set of examples for that FY.
  include_examples 'an LSA legacy FY stub',
                   all_class: Reports::Lsa::Fy2018::All,
                   base_class: Reports::Lsa::Fy2018::Base,
                   report_name: 'LSA - FY 2018'

  include_examples 'an LSA legacy FY stub',
                   all_class: Reports::Lsa::Fy2019::All,
                   base_class: Reports::Lsa::Fy2019::Base,
                   report_name: 'LSA - FY 2019'

  include_examples 'an LSA legacy FY stub',
                   all_class: Reports::Lsa::Fy2021::All,
                   base_class: Reports::Lsa::Fy2021::Base,
                   report_name: 'LSA - FY 2021'
end
