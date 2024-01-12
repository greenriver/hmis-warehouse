###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::AgeCalculations
  extend ActiveSupport::Concern
  included do
    def age_categories
      {
        (0..4) => 'Newborn to 4',
        (5..10) => '5 to 10',
        (11..14) => '11 to 14',
        (15..17) => '15 to 17',
        (18..24) => '18 to 24',
        (25..34) => '25 to 34',
        (35..44) => '35 to 44',
        (45..54) => '45 to 54',
        (55..64) => '55 to 64',
        (65..110) => '65 +',
        [nil] => 'Unknown',
      }
    end

    def age_detail_hash
      {}.tap do |hashes|
        genders.each do |gender_col, gender_label|
          [
            'adult',
            'child',
          ].each do |age_category|
            key = "#{age_category}_#{gender_col}".to_sym
            scope = "#{key}_scope".to_sym

            title = "#{age_category.titleize} #{gender_label}"
            hashes[key.to_s] = {
              title: "Ages - #{title}",
              headers: client_headers,
              columns: client_columns,
              scope: -> { send(scope).joins(:client, :enrollment).distinct },
            }
          end
          age_categories.each do |age_key, title|
            hashes["age_#{age_key}"] = {
              title: title,
              headers: client_headers,
              columns: client_columns,
              scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_age_range(age_key)).distinct },
            }
          end
          age_categories.each do |age_key, age_title|
            genders.each do |gender, gender_title|
              hashes["age_#{age_key}_gender_#{gender}"] = {
                title: "Age - #{age_title} #{gender_title}",
                headers: client_headers,
                columns: client_columns,
                scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_gender_age(gender, age_key)).distinct },
              }
            end
          end
        end
      end
    end

    def adult_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_scope.select(:client_id).distinct.count)
      end
    end

    def adult_scope
      report_scope.joins(:client).where(adult_clause)
    end

    def average_adult_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause)
      end
    end

    def child_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_scope.select(:client_id).distinct.count)
      end
    end

    def child_scope
      report_scope.joins(:client).where(child_clause)
    end

    def average_child_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause)
      end
    end

    genders.each_key do |gender_col|
      [
        'adult',
        'child',
      ].each do |age_category|
        age_category_clause = "#{age_category}_clause"

        define_method "#{age_category}_#{gender_col}_scope" do
          report_scope.joins(:client).where(send(age_category_clause).and(gender_clause(gender_col)))
        end

        define_method "#{age_category}_#{gender_col}_count" do
          Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
            mask_small_population(send("#{age_category}_#{gender_col}_scope").select(:client_id).distinct.count)
          end
        end

        define_method "average_#{age_category}_#{gender_col}_age" do
          Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
            average_age(clause: send(age_category_clause).and(gender_clause(gender_col)))
          end
        end
      end
    end

    def age_coc_count(age_category, coc_code)
      age_category_clause = "#{age_category}_clause"
      mask_small_population(
        report_scope.
          in_coc(coc_code: coc_code).
          joins(:client).
          where(send(age_category_clause)).
          select(:client_id).distinct.count,
      )
    end

    def age_gender_coc_count(age_category, gender_col, coc_code)
      age_category_clause = "#{age_category}_clause"
      mask_small_population(
        report_scope.
          in_coc(coc_code: coc_code).
          joins(:client).
          where(send(age_category_clause).and(gender_clause(gender_col))).
          select(:client_id).distinct.count,
      )
    end

    def age_count(type, coc_code = base_count_sym)
      mask_small_population(clients_in_age_range(type, coc_code)&.count&.presence || 0)
    end

    def clients_in_age_range(type, coc_code = base_count_sym)
      client_ages[coc_code]&.select { |_, age| age.in?(type) }
    end

    def client_ids_in_age_range(type)
      clients_in_age_range(type).keys
    end

    def age_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = age_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def age_data_for_export(rows)
      [
        'adult',
        'child',
      ].each do |age_category|
        age_category_title = age_category.titleize.pluralize
        rows["_#{age_category_title} Break"] ||= []
        rows["*#{age_category_title}"] ||= []
        rows["*#{age_category_title}"] += ['Gender', nil, 'Count', 'Average Age', nil]
        available_coc_codes.each do |coc_code|
          rows["*#{age_category_title}"] += [coc_code]
        end
        rows["*#{age_category_title}"] += [nil]
        rows["_#{age_category_title} - All"] ||= []
        rows["_#{age_category_title} - All"] += ['All', nil, send("#{age_category}_count"), send("average_#{age_category}_age"), nil]
        available_coc_codes.each do |coc_code|
          rows["_#{age_category_title} - All"] += [age_coc_count(age_category, coc_code.to_sym)]
        end
        genders.each do |gender_col, gender_label|
          rows["_#{age_category_title} - #{gender_label}"] ||= []
          rows["_#{age_category_title} - #{gender_label}"] += [gender_label, nil, send("#{age_category}_#{gender_col}_count"), send("average_#{age_category}_#{gender_col}_age"), nil]
          available_coc_codes.each do |coc_code|
            rows["_#{age_category_title} - #{gender_label}"] += [age_gender_coc_count(age_category, gender_col, coc_code.to_sym)]
          end
        end
      end

      rows['_Age Breakdowns Break'] ||= []
      rows['*Age Breakdowns'] ||= []
      rows['*Age Breakdowns'] += ['Age Range', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Age Breakdowns'] += ["#{coc_code} Client"]
        rows['*Age Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Age Breakdowns'] += [nil]
      age_categories.each do |age_range, age_title|
        rows["_Age Breakdowns_data_#{age_title}"] ||= []
        rows["_Age Breakdowns_data_#{age_title}"] += [
          age_title,
          nil,
          age_count(age_range),
          age_percentage(age_range) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Age Breakdowns_data_#{age_title}"] += [
            age_count(age_range, coc_code.to_sym),
            age_percentage(age_range, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def client_ages
      @client_ages ||= Rails.cache.fetch(age_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program).
            each do |client_id, age, _|
              clients[base_count_sym][client_id] ||= age
            end
          available_coc_codes.each do |coc_code|
            clients[coc_code.to_sym] ||= {}
            report_scope.joins(:client).order(first_date_in_program: :desc).
              distinct.in_coc(coc_code: coc_code.to_sym).
              pluck(:client_id, age_calculation, :first_date_in_program).
              each do |client_id, age, _|
                clients[coc_code.to_sym][client_id] ||= age
              end
          end
        end
      end
    end

    private def age_cache_key
      [self.class.name, cache_slug, 'client_ages']
    end
  end
end
