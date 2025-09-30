# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ProcessRecurringHmisExports, type: :model do
  let(:task) { described_class.new }

  describe '#run!' do
    it 'executes exports that are due' do
      due_export = create(:recurring_hmis_export, updated_at: 2.days.ago)
      skip_export = create(:recurring_hmis_export, updated_at: Time.zone.now)

      allow(due_export).to receive(:should_run?).and_return(true)
      allow(skip_export).to receive(:should_run?).and_return(false)

      allow(task).to receive(:recurring_exports_scope).and_return([due_export, skip_export])

      expect(due_export).to receive(:run)
      expect(skip_export).not_to receive(:run)

      task.run!
    end
  end
end
