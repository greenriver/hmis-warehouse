class Import < ActiveRecord::Base
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
      'incomplete'
    end
  end

end