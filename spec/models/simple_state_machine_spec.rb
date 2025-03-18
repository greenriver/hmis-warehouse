
require 'spec_helper'
require 'active_record'

# Set up in-memory database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create a test model
ActiveRecord::Schema.define do
  create_table :workflows do |t|
    t.string :status
    t.timestamps
  end
end

class Workflow < ActiveRecord::Base
  include SimpleStateMachine

  state_machine column: 'status' do
    state :unavailable, initial: true
    state :available
    state :in_progress
    state :completed

    event :enable do
      transitions from: :unavailable, to: :available
    end

    event :disable do
      transitions from: :available, to: :unavailable
    end

    event :start do
      transitions from: :available, to: :in_progress
    end

    event :cancel do
      transitions from: :in_progress, to: :available
    end

    event :complete do
      transitions from: :in_progress, to: :completed
    end

    event :undo_complete_step do
      transitions from: :completed, to: :in_progress
    end
  end
end

RSpec.describe SimpleStateMachine do
  let(:workflow) { Workflow.new }

  describe "initialization" do
    it "sets the initial state" do
      expect(workflow.status).to eq('unavailable')
    end

    it "responds to state predicate methods" do
      expect(workflow.unavailable?).to be true
      expect(workflow.available?).to be false
    end
  end

  describe "transitions" do
    context "valid transitions" do
      it "transitions from unavailable to available" do
        expect(workflow.may_enable?).to be true
        expect(workflow.enable).to be true
        expect(workflow.status).to eq('available')
      end

      it "follows a complete workflow path" do
        workflow.enable
        expect(workflow.available?).to be true

        workflow.start
        expect(workflow.in_progress?).to be true

        workflow.complete
        expect(workflow.completed?).to be true

        workflow.undo_complete_step
        expect(workflow.in_progress?).to be true
      end
    end

    context "invalid transitions" do
      it "cannot transition directly from unavailable to in_progress" do
        expect(workflow.may_start?).to be false
        expect(workflow.start).to be false
        expect(workflow.status).to eq('unavailable')
      end

      it "raises error with bang method on invalid transition" do
        expect { workflow.start! }.to raise_error(/cannot transition/)
      end
    end
  end

  describe "complex transition paths" do
    it "allows transitioning back and forth between states" do
      workflow.enable
      expect(workflow.available?).to be true

      workflow.disable
      expect(workflow.unavailable?).to be true

      workflow.enable
      workflow.start
      expect(workflow.in_progress?).to be true

      workflow.cancel
      expect(workflow.available?).to be true
    end
  end

  describe "persistence" do
    it "persists state changes to the database" do
      workflow.save!
      workflow.enable

      # Reload from database
      reloaded = Workflow.find(workflow.id)
      expect(reloaded.status).to eq('available')
      expect(reloaded.available?).to be true
    end
  end
end
