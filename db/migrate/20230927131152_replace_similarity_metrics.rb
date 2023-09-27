class ReplaceSimilarityMetrics < ActiveRecord::Migration[6.1]
  def change
    SimilarityMetric::Base.where(type: 'SimilarityMetric::Female').update_all(type: 'SimilarityMetric::Woman')
    SimilarityMetric::Base.where(type: 'SimilarityMetric::Male').update_all(type: 'SimilarityMetric::Man')
  end
end
