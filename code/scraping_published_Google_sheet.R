scrapeGoogleSheet_form <- function(link) {
  flight_log <- read_html(link) %>% 
    html_node("table") %>% 
    rvest::html_table() 
  
  # remove first column
  flight_log <- flight_log[,-1]
  # add names to data frame
  names(flight_log) <- flight_log[1,]
  # remove first row
  flight_log <- flight_log[-1,]
  row.names(flight_log) <- NULL
  
  flight_log_cleaned <- flight_log %>% 
    mutate(trip_no = as.integer(trip_no),
           depart_date = as.Date(depart_date, format = '%d/%m/%Y'),
           roundtrip_return_date = as.Date(roundtrip_return_date, format = '%d/%m/%Y'),
           opt_personal = as.character(opt_personal),
           opt_flight_no = as.character(opt_flight_no)) %>% 
    filter(!is.na(trip_no)) 
  
  # calculate Great Circle Distance between airports in flight_log_cleaned 
  flight_log_cleaned$great_circle_dist_km <- mapply(function(x,y) 
    geosphere::distHaversine(
      p1 = longlat_vector[[x]],
      p2 = longlat_vector[[y]])/1000, # to get kms 
    flight_log_cleaned$departure_airport, flight_log_cleaned$arrival_airport, USE.NAMES = F)
  
  one_way_flights <- flight_log_cleaned %>% 
    select(-roundtrip_return_date)
  
  return_flights <- flight_log_cleaned %>% 
    filter(roundtrip == 'Yes') %>% 
    mutate(depart_date = roundtrip_return_date) %>% 
    select(trip_no,arrival_airport, departure_airport, depart_date, roundtrip, class, great_circle_dist_km) %>% 
    rename(departure_airport = arrival_airport,
           arrival_airport = departure_airport)
  
  data_for_viz <- bind_rows(one_way_flights, return_flights) %>% 
    arrange(depart_date) %>% 
    # Reference: https://research.chalmers.se/publication/508693/file/508693_Fulltext.pdf
    mutate(tCO2_eq_kg = 170*great_circle_dist_km/1000,
           month = format(depart_date, '%m'),
           year = format(depart_date, '%Y'),
           yearmon = as.Date(paste('01',month, year, sep = '/'), format = '%d/%m/%Y'),
           quarter = quarter(depart_date, with_year = T)) %>% 
    select(-c('month', 'year')) %>% 
    mutate_at(vars(contains('opt')), funs(ifelse(. == "", yes = NA_character_, .))) %>% 
    # adding departure airport's latlong
    left_join(., departure_latlong, by = c('departure_airport' = 'iata_code')) %>% 
    # adding arrival airport's latlong
    left_join(., arrival_latlong, by = c('arrival_airport' = 'iata_code'))  
  
  data_for_viz
}


write.csv(data_for_viz, here::here('intermediate_data','data_for_viz.csv'))


test_data <- scrapeGoogleSheet_form(default_url)


test_data$depart_date
