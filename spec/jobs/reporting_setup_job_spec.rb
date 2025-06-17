# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportingSetupJob, type: :job do
  describe '#_perform' do
    let(:housed_class) { class_double(Reporting::Housed).as_stubbed_const }
    let(:housed_instance) { instance_double(Reporting::Housed) }
    let(:return_class) { class_double(Reporting::Return).as_stubbed_const }
    let(:return_instance) { instance_double(Reporting::Return) }

    before do
      allow(housed_class).to receive(:new).and_return(housed_instance)
      allow(housed_instance).to receive(:populate!)
      allow(return_class).to receive(:new).and_return(return_instance)
      allow(return_instance).to receive(:populate!)
    end

    it 'populates housed and return reports' do
      described_class.new._perform
      expect(housed_instance).to have_received(:populate!)
      expect(return_instance).to have_received(:populate!)
    end

    it 'populates them in the correct order' do
      expect(housed_class).to receive(:new).ordered
      expect(return_class).to receive(:new).ordered
      described_class.new._perform
    end
  end
end
