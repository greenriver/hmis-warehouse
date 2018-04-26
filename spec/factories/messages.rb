FactoryGirl.define do
  # puts Message.new.attributes
  factory :message do
    from    %w( macbeth@scotland.gov.uk )
    subject 'futility'
    body <<-END.strip_heredoc
        Tomorrow and tomorrow and tomorrow
        Creeps in this petty pace from day to day
        To the last syllable of recorded time,
        And all our yesterdays have lighted fools
        The way to dusty death. Out out, brief candle!
        Life is a walking shadow, a poor player,
        Who struts and frets his hour upon the stage
        And then is heard no more. It is a tale
        Told by an idiot: full of sound and fury,
        Signifying nothing.
    END
  end
end
