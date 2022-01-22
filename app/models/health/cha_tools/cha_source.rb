module Health::ChaTools
  class ChaSource
    def each
      Health::ComprehensiveHealthAssessment.completed.find_each do |cha|
        yield cha.as_interchange
      end
    end
  end
end
