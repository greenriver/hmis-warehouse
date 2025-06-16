# frozen_string_literal: true

require 'rails_helper'

module Reporting
  RSpec.describe PopulationDashboardPopulateJob, type: :job do
    describe '#_perform' do
      let(:report_class_double) { class_double(Reporting::MonthlyReports::Base) }
      let(:report_instance_double) { instance_double(Reporting::MonthlyReports::Base) }

      before do
        allow(Reporting::MonthlyReports::Base).to receive(:class_for).and_return(report_class_double)
        allow(report_class_double).to receive(:new).and_return(report_instance_double)
        allow(report_instance_double).to receive(:populate!)
      end

      context "when sub_population is 'all'" do
        let(:sub_populations) { { youth: 'YouthReport', veterans: 'VeteransReport' } }
        let(:youth_report_double) { instance_double(Reporting::MonthlyReports::Base) }
        let(:veterans_report_double) { instance_double(Reporting::MonthlyReports::Base) }

        before do
          allow(Reporting::MonthlyReports::Base).to receive(:available_types).and_return(sub_populations)
          allow(Reporting::MonthlyReports::Base).to receive(:class_for).with(:youth).and_return(class_double('YouthReport', new: youth_report_double))
          allow(Reporting::MonthlyReports::Base).to receive(:class_for).with(:veterans).and_return(class_double('VeteransReport', new: veterans_report_double))
          allow(youth_report_double).to receive(:populate!)
          allow(veterans_report_double).to receive(:populate!)
        end

        it 'populates all available report types' do
          described_class.new.perform(sub_population: 'all')
          expect(youth_report_double).to have_received(:populate!)
          expect(veterans_report_double).to have_received(:populate!)
        end
      end

      context 'when a specific sub_population is given' do
        let(:youth_report_class_double) { class_double(Reporting::MonthlyReports::Base) }
        let(:youth_report_instance_double) { instance_double(Reporting::MonthlyReports::Base) }
        let(:veterans_report_class_double) { class_double(Reporting::MonthlyReports::Base) }
        let(:veterans_report_instance_double) { instance_double(Reporting::MonthlyReports::Base) }

        before do
          allow(Reporting::MonthlyReports::Base).to receive(:class_for).with(:youth).and_return(youth_report_class_double)
          allow(Reporting::MonthlyReports::Base).to receive(:class_for).with(:veterans).and_return(veterans_report_class_double)
          allow(youth_report_class_double).to receive(:new).and_return(youth_report_instance_double)
          allow(veterans_report_class_double).to receive(:new).and_return(veterans_report_instance_double)
          allow(youth_report_instance_double).to receive(:populate!)
          allow(veterans_report_instance_double).to receive(:populate!)
        end

        it 'populates the specific report' do
          described_class.new.perform(sub_population: 'youth')
          expect(youth_report_instance_double).to have_received(:populate!)
          expect(veterans_report_instance_double).to_not have_received(:populate!)
        end
      end
    end
  end
end
