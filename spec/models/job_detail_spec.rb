# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JobDetail, type: :model do
  let(:job) { Delayed::Job.create!(handler: { 'job_class' => 'ApplicationJob' }.to_yaml) }
  let(:describe) { described_class.new(job) }

  describe '#executor_class' do
    context 'with an ActiveJob wrapper' do
      let(:payload) { double('ActiveJobWrapper', job_data: { 'job_class' => 'Reporting::Hud::RunReportJob' }) }

      before do
        allow(job).to receive(:payload_object).and_return(payload)
      end

      it 'returns the constantized job class' do
        expect(describe.executor_class).to eq(Reporting::Hud::RunReportJob)
      end
    end

    context 'with a .delay PerformableMethod' do
      let(:payload) { double('PerformableMethod', object: HudReports::ReportInstance.new) }

      before do
        allow(job).to receive(:payload_object).and_return(payload)
      end

      it 'returns the class of the object' do
        expect(describe.executor_class).to eq(HudReports::ReportInstance)
      end
    end

    context 'with a .delay PerformableMethod on a Module' do
      let(:payload) { double('PerformableMethod', object: HudReports) }

      before do
        allow(job).to receive(:payload_object).and_return(payload)
      end

      it 'returns the Module itself' do
        expect(describe.executor_class).to eq(HudReports)
      end
    end

    context 'with a plain Delayed::Job' do
      let(:payload) { double('PlainJob') }

      before do
        allow(job).to receive(:payload_object).and_return(payload)
      end

      it 'returns the class of the payload object' do
        expect(describe.executor_class).to eq(payload.class)
      end
    end
  end

  describe '#interruptible?' do
    before do
      stub_const('TestInterruptibleJob', Class.new(ApplicationJob) do
        def self.interruptible? = true
      end)
      stub_const('TestNonInterruptibleJob', Class.new(ApplicationJob))
    end

    it 'returns true for interruptible jobs' do
      payload = double('ActiveJobWrapper', job_data: { 'job_class' => 'TestInterruptibleJob' })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.interruptible?).to be true
    end

    it 'returns false for non-interruptible jobs' do
      payload = double('ActiveJobWrapper', job_data: { 'job_class' => 'TestNonInterruptibleJob' })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.interruptible?).to be false
    end
  end

  describe '#job_name' do
    it 'returns the name from the job' do
      allow(job).to receive(:name).and_return('Reporting::Hud::RunReportJob (args)')
      expect(describe.job_name).to eq('Reporting::Hud::RunReportJob')
    end
  end

  describe '#arguments' do
    it 'returns arguments for ActiveJob' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => [1, 2] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.arguments).to eq([1, 2])
    end

    it 'returns arguments for PerformableMethod' do
      payload = double('PerformableMethod', args: [3, 4])
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.arguments).to eq([3, 4])
    end
  end

  describe '#job_class' do
    context 'for HUD reports' do
      it 'extracts the report class from arguments' do
        payload = double('ActiveJobWrapper', job_data: {
                           'job_class' => 'Reporting::Hud::RunReportJob',
                           'arguments' => ['HudSpmReport::Fy2026::Generator', 'report-id'],
                         })
        allow(job).to receive(:payload_object).and_return(payload)
        expect(describe.job_class).to eq('HudSpmReport::Fy2026::Generator')
      end
    end

    context 'for BackgroundRender' do
      it 'returns the job name' do
        allow(job).to receive(:name).and_return('BackgroundRender::SomeJob')
        stub_const('BackgroundRender::SomeJob', Class.new(ApplicationJob))
        payload = double('ActiveJobWrapper', job_data: {
                           'job_class' => 'BackgroundRender::SomeJob',
                           'arguments' => [],
                         })
        allow(job).to receive(:payload_object).and_return(payload)
        expect(describe.job_class).to eq('BackgroundRender::SomeJob')
      end
    end
  end
end
