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

    context 'with a non-existent class' do
      it 'returns nil and does not crash' do
        payload = double('ActiveJobWrapper', job_data: { 'job_class' => 'NonExistentClass' })
        allow(job).to receive(:payload_object).and_return(payload)
        expect(describe.executor_class).to be_nil
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

    it 'returns arguments when payload is a Hash' do
      payload = { 'arguments' => [5, 6] }
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.arguments).to eq([5, 6])
    end
  end

  describe '#user_id' do
    context 'with Hash arguments' do
      let(:payload) { double('ActiveJobWrapper', job_data: { 'arguments' => { 'user_id' => 123 } }) }
      before { allow(job).to receive(:payload_object).and_return(payload) }

      it 'returns user_id from the hash' do
        expect(describe.user_id).to eq(123)
      end
    end

    context 'with Array arguments' do
      let(:payload) { double('ActiveJobWrapper', job_data: { 'arguments' => [{ 'user_id' => 456 }] }) }
      before { allow(job).to receive(:payload_object).and_return(payload) }

      it 'returns user_id from the first element' do
        expect(describe.user_id).to eq(456)
      end
    end

    context 'for BackgroundRender' do
      before do
        allow(job).to receive(:name).and_return('BackgroundRender::ExportJob (args)')
      end

      it 'returns user_id from the last element if it is a Hash' do
        payload = double('ActiveJobWrapper', job_data: { 'arguments' => ['some-arg', { 'user_id' => 789 }] })
        allow(job).to receive(:payload_object).and_return(payload)
        expect(describe.user_id).to eq(789)
      end

      it 'handles cases where arguments is a Hash' do
        payload = double('ActiveJobWrapper', job_data: { 'arguments' => { 'user_id' => 101 } })
        allow(job).to receive(:payload_object).and_return(payload)
        expect(describe.user_id).to eq(101)
      end
    end

    context 'for Reporting::Hud::RunReportJob' do
      before do
        allow(job).to receive(:name).and_return('Reporting::Hud::RunReportJob')
      end

      it 'returns user_id from the report instance' do
        report_instance = instance_double('HudReports::ReportInstance', user_id: 202)
        allow(HudReports::ReportInstance).to receive(:find_by).and_return(report_instance)
        payload = double('ActiveJobWrapper', job_data: { 'arguments' => ['class', 'report-id'] })
        allow(job).to receive(:payload_object).and_return(payload)

        expect(describe.user_id).to eq(202)
      end
    end

    it "returns 'unknown' by default" do
      expect(describe.user_id).to eq('unknown')
    end
  end

  describe '#report_id' do
    it 'extracts report_id from hash arguments' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => { 'report_id' => 'ABC' } })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq('ABC')
    end

    it 'extracts first element if it is a String or Numeric' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => [789, 'other'] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq(789)
    end

    it 'extracts report_id from first element hash' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => [{ 'report_id' => 'XYZ' }] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq('XYZ')
    end

    it 'extracts last element if it is an Integer' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => ['class', 999] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq(999)
    end

    it 'extracts report_id from second element for RunReportJob' do
      allow(job).to receive(:name).and_return('Reporting::Hud::RunReportJob')
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => ['SomeClass', 123, { email: true }] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq(123)
    end

    it 'prefers second argument if first is a class string' do
      payload = double('ActiveJobWrapper', job_data: { 'arguments' => ['MyClass', 456, {}] })
      allow(job).to receive(:payload_object).and_return(payload)
      expect(describe.report_id).to eq(456)
    end
  end

  describe '#created_at' do
    it 'returns created_at from hud_report_instance' do
      now = Time.current
      report_instance = instance_double('HudReports::ReportInstance', created_at: now)
      allow(HudReports::ReportInstance).to receive(:find_by).and_return(report_instance)
      allow(describe).to receive(:arguments).and_return(['class', 'report-id'])
      allow(job).to receive(:name).and_return('Reporting::Hud::RunReportJob')

      expect(describe.created_at).to eq(now)
    end
  end

  describe '.queue_status' do
    it 'returns status grouped by queue' do
      Delayed::Job.delete_all
      Delayed::Job.create!(queue: 'default_priority', handler: '---')
      Delayed::Job.create!(queue: 'long_running', handler: '---')
      Delayed::Job.create!(queue: 'long_running', handler: '---')

      expect(described_class.queue_status).to eq({
                                                   'Default priority' => 1,
                                                   'Long running' => 2,
                                                 })
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
