###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'collections:cleanup_orphaned_entities' do
  let(:rake) { Rake::Application.new }
  let(:task_name) { 'collections:cleanup_orphaned_entities' }

  before do
    Rake.application = rake
    Rake::Task.define_task(:environment)
    Rake.load_rakefile(Rails.root.join('lib/tasks/collections.rake'))
  end

  after { rake[task_name].reenable }

  it 'defaults to live mode when no arg is given' do
    expect { Rake::Task[task_name].invoke }.to output(/Mode: LIVE/).to_stdout
  end

  it 'runs in dry run mode when passed true' do
    expect { Rake::Task[task_name].invoke('true') }.to output(/Mode: DRY RUN/).to_stdout
  end

  it 'reports none found when there are no candidates' do
    expect { Rake::Task[task_name].invoke('true') }.to output(/No orphaned system collections found\./).to_stdout
  end

  it 'finds and deletes a real orphan end-to-end' do
    cohort = create(:cohort)
    collection = cohort.viewable_access_control.collection
    cohort.really_destroy!

    expect { Rake::Task[task_name].invoke }.to output(/Collection ##{collection.id}.* - deleted/).to_stdout
    expect(Collection.find_by(id: collection.id)).to be_nil
  end

  it 'does not delete anything in dry run mode' do
    cohort = create(:cohort)
    collection = cohort.viewable_access_control.collection
    cohort.really_destroy!

    Rake::Task[task_name].invoke('true')

    expect(Collection.find_by(id: collection.id)).to be_present
  end

  it 'treats "1" the same as "true" for dry run mode' do
    cohort = create(:cohort)
    collection = cohort.viewable_access_control.collection
    cohort.really_destroy!

    Rake::Task[task_name].invoke('1')

    expect(Collection.find_by(id: collection.id)).to be_present
  end

  it 'reports a per-candidate error and reflects it in the summary when one fails to delete' do
    cohort = create(:cohort)
    collection = cohort.viewable_access_control.collection
    cohort.really_destroy!

    allow_any_instance_of(Collection).to receive(:destroy_with_associated_records!).and_raise(StandardError, 'simulated failure')

    expect { Rake::Task[task_name].invoke }.to output(
      /Collection ##{collection.id}.*ERROR: simulated failure.*Total deleted: 0.*Total errors: 1/m,
    ).to_stdout
    expect(Collection.find_by(id: collection.id)).to be_present
  end
end
