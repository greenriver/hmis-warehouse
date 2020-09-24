RSpec.shared_examples 'question nine' do
  describe 'Q9: Contacts and Engagements' do
    before(:all) do
      options = default_options.merge(night_by_night_shelter)
      HudApr::Generators::Shared::Fy2020::QuestionNine.new(options: options).run!
    end

    describe 'Q9a: Number of Persons Contacted' do
    end

    describe 'Q9b: Number of Persons Engaged' do
    end
  end
end
