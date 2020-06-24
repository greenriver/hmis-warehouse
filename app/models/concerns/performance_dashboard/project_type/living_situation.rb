###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::LivingSituation
  extend ActiveSupport::Concern

  def enrolled
    open_enrollments.joins(:enrollment)
  end

  # Fetch first prior living situation for each client
  def prior_living_situations
    @prior_living_situations ||= begin
      buckets = HUD.living_situations.keys.map { |b| [b, []] }.to_h
      counted = Set.new
      enrolled.order(first_date_in_program: :desc).
        pluck(:client_id, she_t[:id], e_t[:LivingSituation], :first_date_in_program).each do |c_id, en_id, situation, _|
        buckets[situation] ||= []
        # Store enrollment id so we can fetch details later, unique on client id
        buckets[situation] << en_id unless counted.include?(c_id)
        counted << c_id
      end

      # expose top 5 plus other
      top_situations = buckets.
        # Ignore blank, 8, 9, 99
        reject { |k, _| k.in?([nil, 8, 9, 99]) }.
        sort_by { |_, v| v.count }.
        last(10).to_h
      top_situations[:other] = buckets.except(*top_situations.keys).
        map do |_, v|
          v
        end.flatten
      top_situations
    end
  end

  def prior_living_situations_data_for_chart
    @prior_living_situations_data_for_chart ||= begin
      columns = [date_range_words]
      columns += prior_living_situations.values.map(&:count).reverse
      categories = prior_living_situations.keys.reverse.map do |k|
        if k == :other
          'All others'
        else
          HUD.living_situation(k)
        end
      end
      {
        columns: columns,
        categories: categories,
      }
    end
  end

  def living_situation_bucket_titles
    HUD.living_situations
  end

  private def living_situation_details(options)
    sub_key = if options[:sub_key].present?
      options[:sub_key]&.to_i
    else
      :other
    end

    ids = prior_living_situations[sub_key]
    details = enrolled.joins(:client, :enrollment).
      where(id: ids).
      order(first_date_in_program: :desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end

  private def living_situation_detail_headers(options)
    detail_columns(options).keys
  end
end
