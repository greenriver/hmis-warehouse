require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2020::QuestionNine, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup

    options = default_options.merge(night_by_night_shelter)
    HudApr::Generators::Apr::Fy2020::QuestionNine.new(options: options).run!
  end

  after(:all) do
    cleanup
  end

  describe 'Q9a: Number of Persons Contacted' do
  end

  describe 'Q9b: Number of Persons Engaged' do
  end
end
