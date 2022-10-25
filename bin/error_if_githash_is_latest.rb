#!/usr/bin/env ruby

githash = ENV['GITHASH']
variants = ARGV[0].split(',')
ecr_repository = ENV['ECR_REPOSITORY']

all_variants_latest = true

variants.each do |variant|
  tags = `aws ecr describe-images --repository-name #{ecr_repository} --image-ids imageTag=githash-#{githash}--#{variant} --query=imageDetails[0].imageTags`

  if tags.include?('latest')
    puts "Variant #{variant} has a latest tag for githash #{githash}"
  else
    all_variants_latest = false
  end
end

raise "All variants have a latest tag for githash #{githash}, refusing to rebuild" if all_variants_latest
