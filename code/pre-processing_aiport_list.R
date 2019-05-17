# importing raw airport code data
airports_raw <- read.csv(file = here::here('raw_data', 'airports.csv'), stringsAsFactors = F)

airports_only <- subset(x = airports_raw, 
                        # want airports with valid IATA codes and exclude small ones
                        type %in% c("large_airport", 'medium_airport') & 
                          nchar(iata_code) > 2 & 
                          latitude_deg != 0 & 
                          longitude_deg != 0) %>% 
  distinct(iata_code, .keep_all = T)

longlat_vector <- mapply(function(y,z) list(c(y,z)), 
                         airports_only$longitude_deg, airports_only$latitude_deg)
names(longlat_vector) <- airports_only$iata_code

saveRDS(longlat_vector, file = here::here('intermediate_data', 'longlat_vector.RDS'))

departure_latlong <- airports_only %>% 
  select(iata_code, latitude_deg, longitude_deg) %>% 
  rename(dep_lat = latitude_deg,
         dep_long = longitude_deg) %>% 
  mutate(iata_code = as.character(iata_code))

arrival_latlong <- airports_only %>% 
  select(iata_code, latitude_deg, longitude_deg) %>% 
  rename(arriv_lat = latitude_deg,
         arriv_lon = longitude_deg) %>% 
  mutate(iata_code = as.character(iata_code))



write.csv(airports_only, file = here::here('intermediate_data', 'airports_only.csv'), row.names = F)
write.csv(departure_latlong, file = here::here('intermediate_data', 'departure_latlong.csv'), row.names = F)
write.csv(arrival_latlong, file = here::here('intermediate_data', 'arrival_latlong.csv'), row.names = F)