# require 'rserve/simpler'
require 'rinruby'
module Reporting
  class RrhReport

    attr_accessor :program_1_name, :program_2_name
    def initialize program_1_name:, program_2_name:
      self.program_1_name = program_1_name
      self.program_2_name = program_2_name
    end

    def r
      R
    end

    def set_time_format
      # We need this for exporting to the appropriate format
      @default_date_format = Date::DATE_FORMATS[:default]
      @default_time_format = Time::DATE_FORMATS[:default]
      Date::DATE_FORMATS[:default] = "%Y-%m-%d"
      Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    end

    def reset_time_format
      Date::DATE_FORMATS[:default] = @default_date_format
      Time::DATE_FORMATS[:default] = @default_time_format
    end

    def housed
      @housed ||= Reporting::Housed.all
    end

    def returns
      @returns ||= Reporting::Return.all
    end

    def program_1_selected
      @program_1_selected ||= program_selected(program_1_name)
    end

    def program_2_selected
      @program_2_selected ||= program_selected(program_2_name)
    end

    def housed_1
      @housed_1 ||= housed.where(residential_project: program_1_selected)
    end


    def housed_2
      @housed_2 ||= housed.where(residential_project: program_2_selected)
    end

    def program_selected program_name
      if program_name == 'All'
        housed.distinct.pluck(:residential_project)
      else
        housed.distinct.where(residential_project: program_name).pluck(:residential_project)
      end
    end

    def r
      @r ||= Rserve::Simpler.new
    end

    def set_r_variables
      set_time_format
      housed_file = Tempfile.new('housed')
      CSV.open(housed_file, 'wb') do |csv|
        csv << housed.first.attributes.keys
        housed.each do |m|
          csv << m.attributes.values
        end
      end
      # housed_file.write(housed.to_json)
      # housed_file.rewind
      # puts housed_file.path

      returns_file = Tempfile.new('housed')
      CSV.open(returns_file, 'wb') do |csv|
        csv << returns.first.attributes.keys
        returns.each do |m|
          csv << m.attributes.values
        end
      end
      # returns_file.write(returns.to_json)
      # returns_file.rewind
      # puts returns_file.path

      # R.housed_json = housed.first(100).to_json
      # R.returns_json = returns.first(100).to_json
      R.program_1 = program_1_name
      R.program_2 = program_2_name

      R.eval <<~REOF
        library('dplyr')
        library('magrittr')
        library('jsonlite')

        housed <- read.csv("#{housed_file.path}")
        # housed <- fromJSON(txt='#{housed_file.path}')

        housed$month_year <- as.Date(housed$month_year)
        housed$search_start <- as.Date(housed$search_start)
        housed$search_end <- as.Date(housed$search_end)
        housed$housed_date <- as.Date(housed$housed_date)
        housed$housing_exit <- as.Date(housed$housing_exit)
        housed$destination <- as.character(housed$destination)
        # print(housed)

        returns <- read.csv("#{returns_file.path}")
        # returns <- fromJSON(txt='#{returns_file.path}')

        returns$start_date <- as.Date(returns$start_date)
        returns$end_date <- as.Date(returns$end_date)
        # print(returns)

        if(program_1=="All")
        {
          housed_1 <- housed
        } else
        {
          housed_1 <- housed %>% filter(residential_project == program_1)
        }
        if(program_2=="All")
        {
          housed_2 <- housed
        } else
        {
          housed_2 <- housed %>% filter(residential_project == program_2)
        }

        print(head(housed_1, n=5))
        print(head(housed_2, n=5))

        #retrieve post-housing ES or SO records for clients housed through the first program
        first_housed_dates <- housed_1 %>%
          #filter(ph_destination=="ph") %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        print(head(first_housed_dates, n=5))

        services_with_housed_dates <- returns %>%
          filter(client_id %in% first_housed_dates$client_id) %>%
          left_join(first_housed_dates, on = c("client_id" = "client_id"))

        print(head(services_with_housed_dates, n=5))

        post_housing <- services_with_housed_dates %>%
          filter(start_date > housing_exit) %>%
          filter(project_type %in% c(1,2,4)) %>%
          arrange(client_id, start_date)

        print(head(post_housing, n=5))

        post_housing <- post_housing[!is.na(post_housing$start_date),]
        post_housing <- post_housing[!is.na(post_housing$end_date),]

        l <- mapply(seq.Date, post_housing$start_date, post_housing$end_date, 1)
        df2 <- data.frame(group = rep(post_housing$client_id,sapply(l,length)),
                          dates = unlist(l))
        unique_dates = aggregate(dates ~ group, df2, function(x) length(unique(x)))
        post_housing = left_join(post_housing, unique_dates, by=c("client_id"="group"))
        post_housing %<>% mutate(
          adjusted_days_homeless = dates
        ) %>%
          select(-dates)
        post_housing_1 <- post_housing

        print(head(post_housing_1, n=5))

        #retrieve post-housing ES or SO records for clients housed through the second program
        first_housed_dates <- housed_2 %>%
          #filter(ph_destination=="ph") %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        print(head(first_housed_dates, n=5))

        # services_with_housed_dates <- returns %>%
        #   filter(client_id %in% first_housed_dates$client_id) %>%
        #   left_join(first_housed_dates, on = c("client_id" = "client_id"))

        # post_housing <- services_with_housed_dates %>%
        #   filter(start_date > housing_exit) %>%
        #   filter(project_type %in% c(1,2,4)) %>%
        #   arrange(client_id, start_date)

        # post_housing <- post_housing[!is.na(post_housing$start_date),]
        # post_housing <- post_housing[!is.na(post_housing$end_date),]
        # l <- mapply(seq.Date, post_housing$start_date, post_housing$end_date, 1)
        # df2 <- data.frame(group = rep(post_housing$client_id,sapply(l,length)),
        #                   dates = unlist(l))
        # unique_dates = aggregate(dates ~ group, df2, function(x) length(unique(x)))
        # post_housing = left_join(post_housing, unique_dates, by=c("client_id"="group"))
        # post_housing %<>% mutate(
        #   adjusted_days_homeless = dates
        # ) %>%
        #   select(-dates)
        # post_housing_2 <-post_housing

        # print(head(post_housing_2, n=5))

      REOF

      # housed_file.close
      # housed_file.unlink
      # returns_file.close
      # returns_file.unlink
      reset_time_format
    end
  end
end