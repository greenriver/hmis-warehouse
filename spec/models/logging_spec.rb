require 'rails_helper'

RSpec.describe 'Logging', type: :model do
  it 'works without tagging at all' do
    Rails.logger.info('Test no tagging')
  end

  it 'works with key/value tags' do
    Rails.logger.tagged({process_name: "nightly-process-1"}) do
      Rails.logger.info('Test one tag')
    end

    Rails.logger.tagged(process_name: "nightly-process-1") do
      Rails.logger.info('Test one tag')
    end

    Rails.logger.tagged([{process_name: "nightly-process-1"}]) do
      Rails.logger.info('Test one tag')
    end
  end

  it 'works with boolean tagging' do
    Rails.logger.tagged('Test') do
      Rails.logger.info('Test one tag')
    end
  end

  it 'works with list of boolean tags' do
    Rails.logger.tagged('Test', 'Test2') do
      Rails.logger.info('Test two tags')
    end

    Rails.logger.tagged(['Test', 'Test2']) do
      Rails.logger.info('Test two tags')
    end

    Rails.logger.tagged(*['Test', 'Test2']) do
      Rails.logger.info('Test two tags')
    end
  end

  it 'works with no tags' do
    Rails.logger.tagged do
      Rails.logger.info('Test no tags')
    end
  end

  it 'works with nested tags, albiet without merging them' do
    Rails.logger.tagged('Test') do
      Rails.logger.tagged('InnerTest') do
        Rails.logger.info('Test dual tagged blocks')
      end
    end
  end
end
