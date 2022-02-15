###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Import < ApplicationRecord
  require 'csv'
  include ActionView::Helpers::DateHelper
  acts_as_paranoid

  mount_uploader :file, ImportUploader
  validates :source, presence: true
  validates :file, presence: true

  def status
    if percent_complete == 0
      'Queued'
    elsif percent_complete == 0.01
      'Started'
    elsif percent_complete == 100
      'Complete'
    else
      percent_complete
    end
  end

  def import_time
    if percent_complete == 100
      seconds = ((completed_at - created_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    else
      if updated_at < 2.days.ago
        'failed'
      else
        'processing...'
      end
    end
  end

end
