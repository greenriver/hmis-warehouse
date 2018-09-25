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

    def housed
      @housed ||= Reporting::Housed.all
    end

    def returns
      @returns ||= Reporting::Return.all
    end

    def r
      @r ||= Rserve::Simpler.new
    end

    def set_r_variables
      housed_file = Tempfile.new('housed')
      housed_file.write(housed.first(5).to_json)
      housed_file.rewind
      puts housed_file.path

      returns_file = Tempfile.new('housed')
      returns_file.write(returns.first(5).to_json)
      returns_file.rewind
      puts returns_file.path

      # R.housed_json = housed.first(100).to_json
      # R.returns_json = returns.first(100).to_json
      R.program_1 = program_1_name
      R.program_2 = program_2_name

      R.eval <<~REOF
        require('dplyr')
        require('magrittr')
        library('jsonlite')

        housed <- fromJSON(txt='#{housed_file.path}')
        print(housed)

        returns <- fromJSON(txt='#{returns_file.path}')
        print(returns)

        if(program_1=="All")
        {
          program_1_selected <- levels(housed$residential_project)
        } else
        {
          program_1_selected <- program_1
        }
        if(program_2=="All")
        {
          program_2_selected <- levels(housed$residential_project)
        } else
        {
          program_2_selected <- program_2
        }

        housed_1 <- housed %<>% filter(residential_project %in% program_1_selected)
        housed_2 <- housed %<>% filter(residential_project %in% program_2_selected)

        print(housed_1)
        print(housed_2)

        #retrieve post-housing ES or SO records for clients housed through the first program
        first_housed_dates <- housed_1 %>%
          #filter(ph_destination=="ph") %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        services_with_housed_dates <- returns %>%
          filter(client_id %in% first_housed_dates$client_id) %>%
          left_join(first_housed_dates, on = c("client_id" = "client_id"))

        post_housing <- services_with_housed_dates %>%
          filter(start_date > housing_exit) %>%
          filter(project_type %in% c(1,2,4)) %>%
          arrange(client_id, start_date)

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

        print(post_housing_1)

        #retrieve post-housing ES or SO records for clients housed through the second program
        first_housed_dates <- housed_2 %>%
          #filter(ph_destination=="ph") %>%
          arrange(client_id, housing_exit) %>%
          group_by(client_id) %>%
          distinct(client_id, .keep_all=TRUE) %>%
          select(client_id, housing_exit)

        services_with_housed_dates <- returns %>%
          filter(client_id %in% first_housed_dates$client_id) %>%
          left_join(first_housed_dates, on = c("client_id" = "client_id"))

        post_housing <- services_with_housed_dates %>%
          filter(start_date > housing_exit) %>%
          filter(project_type %in% c(1,2,4)) %>%
          arrange(client_id, start_date)

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
        post_housing_2 <-post_housing

        print(post_housing_2)

      REOF

      housed_file.close
      housed_file.unlink
      returns_file.close
      returns_file.unlink
    end
  end
end