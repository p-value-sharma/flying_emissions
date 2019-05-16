# packages ####
library(plotly)
library(shiny)
library(shinythemes)
library(dplyr)
library(rgdal)

# load data ####
data_for_viz <- read.csv(here::here('intermediate_data', 'data_for_viz.csv'))

# I used https://xkcd.com/977/ to choose a map projection, don't @ me. 
geo <- list(
  scope = 'world',
  projection = list(type = 'winkel tripel'),
  showland = TRUE,
  showcountries = TRUE,
  showocean = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray80"),
  oceancolor = toRGB("white")
)


p <- plot_geo(data_for_viz) %>%
  add_segments(
    x = ~dep_long, xend = ~arriv_lon,
    y = ~dep_lat, yend = ~arriv_lat,
    alpha = 0.5, size = I(2), color = I("red"), hoverinfo = "none"
  ) %>% 
  layout(
    title = 'Flights',
    showlegend = FALSE,
    geo = geo)
p


chart_link <-  api_create(p, filename="map-flights")
chart_link


# define UI ####

# define server function ####
plot(world_map)

# Create Shiny object ####
shinyApp(ui = ui, server = server)