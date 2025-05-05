###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  class CandidatePoolBuilderJob < BaseJob
    include NotifierConfig

    def perform
      log("Building candidate pools for #{Hmis::Ce::Opportunity.active.count} active opportunities")
      Hmis::Ce::Match::CandidatePoolBuilder.new.perform

      log("Running the CE match engine for #{Hmis::Hud::Client.hmis.count} HMIS clients")
      clients = Hmis::Hud::Client.hmis
      Hmis::Ce::Match::CandidatePool.all.find_each do |pool|
        Hmis::Ce::Match::Engine.call(pool, clients)
      end
    end

    def log(message)
      @notifier&.ping("[CandidatePoolBuilderJob] #{message}")
    end
  end
end
