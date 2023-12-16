# module PerformanceMeasurement
#   class FakeEquityAnalysisData
#     METRICS = [
#       'Number of Homeless People Seen on Jan 26, 2022',
#       'Number of Homeless People Seen Throughout the Year',
#       'Number of First-Time Homeless People',
#       'Average Bed Utilization Overall',
#       'Length of Time Homeless in ES, SH and TH',
#       'Length of Time Homeless in ES, SH, TH, and PH',
#       'Length of Homeless Stay',
#       'Length of Time to Move-In',
#       'Percentage of People with a Successful Placement or Retention of Housing',
#       'Percentage of People Who Returned to Homelessness Within Two Years',
#       'Number of People with Increased Income',
#     ].freeze

#     RACES = [
#       'American Indian, Alaska Native, or Indigenous',
#       'Asian or Asian American',
#       'Black, African American, or African',
#       'Native Hawaiian or Pacific Islander',
#       'White',
#       'Hispanic/Latina/e/o',
#       'Middle Eastern or North African',
#       'Doesn\'t know, prefers not to answer, or not collected',
#       'Multi-Racial',
#     ].freeze

#     # AGES = [
#     #   '0 - 4',
#     #   '5 - 10',
#     #   '11 - 14',
#     #   '15 - 17',
#     #   '< 18',
#     #   '18 - 24',
#     #   '25 - 29',
#     #   '30 - 34',
#     #   '35 - 39',
#     #   '40 - 44',
#     #   '45 - 49',
#     #   '50 - 54',
#     #   '55 - 59',
#     #   '60 - 61',
#     #   '62 - 64',
#     #   '65+',
#     # ].freeze
#     AGES = Filters::FilterBase.available_age_ranges

#     GENDERS = [
#       'Woman (Girl, if child)',
#       'Man (Boy, if child)',
#       'Culturally Specific Identity (e.g., Two-Spirit)',
#       'Non-Binary',
#       'Transgender',
#       'Questioning',
#       'Different Identity',
#       'Client doesn\'t know',
#       'Data not collected',
#     ].freeze

#     HOUSEHOLD_TYPES = [
#       'Adult and Child Households',
#       'Adult and Child Households With HoH 18-24',
#       'Adult and Child Households With HoH 25+',
#       'Adult only Households',
#       'Child only Households',
#       'Non-Veteran',
#       'Veterans',
#     ].freeze

#     BARS = [
#       'Current Period - Report Universe',
#       'Comparison Period - Report Universe',
#       'Current Period - Current Filters',
#       'Comparison Period - Current Filters',
#       # 'Current Period - Census',
#       # 'Comparison Period - Census',
#     ].freeze

#     COLORS = [
#       '#4093A5',
#       '#4093A5',
#       '#182E4E',
#       '#182E4E',
#       '#EE7850',
#       '#EE7850',
#     ].freeze

#     BAR_HEIGHT = 10
#     PADDING = 3
#     RATIO = 0.6

#     MIN_HEIGHT = 200

#     INVESTIGATE_BY = {
#       race: RACES,
#       age: AGES,
#       gender: GENDERS,
#       household_type: HOUSEHOLD_TYPES,
#     }.freeze

#     def initialize(params, report)
#       @params = params
#       @report = report
#     end

#     def data_groups(key)
#       groups = INVESTIGATE_BY[key]
#       # if INVESTIGATE_BY matches one of the filters only show this item in the chart
#       if key == :age
#         groups = AGES.values.include?(@params[:age]&.to_sym) ? AGES.select{ |k, v| v == @params[:age].to_sym} : AGES
#       else
#         groups = groups.select { |g| g == @params[key] } if @params[key].present?
#       end
#       groups
#     end

#     def data(key)
#       if key == :age
#         data_age
#       else
#         groups = data_groups(key)
#         x = [['x'] + groups]
#         {
#           columns: x + BARS.map { |bar| [bar] + groups.map { |_| rand(100) } },
#           ordered_keys: BARS,
#           colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
#         }
#       end
#     end

#     def data_age
#       # groups = AGES.values.include?(@params[:age]&.to_sym) ? AGES.select{ |k, v| v == @params[:age].to_sym} : AGES
#       groups = data_groups(:age)
#       x = [['x'] + groups.keys]
#       {
#         columns: x + BARS.map { |bar| [bar] + groups.values.map { |group| bar_data(universe: bar, breakdown: :age, metric: group) } },
#         ordered_keys: BARS,
#         colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
#       }
#     end

#     def bar_data(universe: nil, breakdown: nil, metric: nil)
#       scope = case universe
#       when 'Current Period - Report Universe'
#         case breakdown
#         when :age
#           age_range = Filters::FilterBase.age_range(metric.to_sym)
#           @report.clients.where(reporting_age: age_range)
#         end
#       when 'Comparison Period - Report Universe'
#         case breakdown
#         when :age
#           age_range = Filters::FilterBase.age_range(metric.to_sym)
#           @report.clients.where(comparison_age: age_range)
#         end
#       when 'Current Period - Current Filters'
#         case breakdown
#         when :age
#           age_range = Filters::FilterBase.age_range(metric.to_sym)
#           apply_params(
#             @report.clients.where(reporting_age: age_range),
#             'reporting'
#           )
#         end
#       when 'Comparison Period - Current Filters'
#         case breakdown
#         when :age
#           age_range = Filters::FilterBase.age_range(metric.to_sym)
#           apply_params(
#             @report.clients.where(comparison_age: age_range),
#             'comparison'
#           )
#         end
#       end
#       scope.count
#     end

#     def apply_params(scope, period)
#       if @params[:age].present?
#         age_range = Filters::FilterBase.age_range(@params[:age].to_sym)
#         scope = scope.where("#{period}_age" => age_range)
#       end
#       scope
#     end

#     def chart_height(key)
#       groups = data_groups(key)
#       bars = BARS.count * (BAR_HEIGHT + PADDING)
#       total = bars / RATIO
#       height = groups.count * total
#       height < MIN_HEIGHT ? MIN_HEIGHT : height
#     end
#   end
# end
