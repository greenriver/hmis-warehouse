require 'rails_helper'

RSpec.describe 'Logging', type: :model do
  it 'works without tagging at all' do
    Rails.logger.info('Test no tagging')
  end

  it 'works with key/value tags' do
    Rails.logger.tagged({process_name: "nightly-process-1"}) do
      Rails.logger.info('Test hash passed')
    end

    Rails.logger.tagged(process_name: "nightly-process-1") do
      Rails.logger.info('Test named args passed')
    end

    Rails.logger.tagged([{process_name: "nightly-process-1"}]) do
      Rails.logger.info('Test array of hash pased')
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
      Rails.logger.info('Test two tags as array')
    end

    Rails.logger.tagged(*['Test', 'Test2']) do
      Rails.logger.info('Test two tags passed with splat')
    end
  end

  it 'works with no tags' do
    Rails.logger.tagged do
      Rails.logger.info('Test empty set of tags')
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
