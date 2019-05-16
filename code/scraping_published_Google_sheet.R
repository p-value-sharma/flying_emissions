# packages 
library(rvest)
library(dplyr)
library(geosphere)
library(lubridate)


# webscraping google sheet #####
link <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vRHvr69sISXqaYL9DA0jeUl0TIe-OTXdSS7JgIQCfmL3jboMEEt7ZK-3L4hLPLeAuXw_y15xBSjD_hj/pubhtml?gid=0&single=true"

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
         roundtrip_return_date = as.Date(roundtrip_return_date, format = '%d/%m/%Y')) %>% 
  filter(!is.na(trip_no)) %>% 
  select(-trip_no)

write.csv(flight_log_cleaned, here::here('intermediate_data','flight_log_cleaned.csv'))


# creating list of airport lat long ####
airports_only <- read.csv(here::here('intermediate_data', 'airports_only.csv'))

longlat_vector <- mapply(function(y,z) list(c(y,z)), 
                         airports_only$longitude_deg, airports_only$latitude_deg)
names(longlat_vector) <- airports_only$iata_code
# calculate Great Circle Distance between airports in flight_log_cleaned ####

# could have used the distVincentyEllipsoid function, but distHaversine is faster and the big uncertainty 
# comes from the tCO2 per passenger per km, so I'm not going to worry about fake certainty
flight_log_cleaned$great_circle_dist_km <- mapply(function(x,y) 
  geosphere::distHaversine(
    p1 = longlat_vector[[x]],
    p2 = longlat_vector[[y]])/1000,
       flight_log_cleaned$departure_airport, flight_log_cleaned$arrival_airport, USE.NAMES = F)



# calculate flight emissions #####

one_way_flights <- flight_log_cleaned %>% 
  select(-c('roundtrip', 'roundtrip_return_date'))
         
return_flights <- flight_log_cleaned %>% 
  filter(roundtrip == 'Yes') %>% 
  mutate(depart_date = roundtrip_return_date) %>% 
  select(arrival_airport, departure_airport, depart_date, class, great_circle_dist_km) %>% 
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
  select(-c('month', 'year'))


write.csv(data_for_viz, here::here('intermediate_data','data_for_viz.csv'))


