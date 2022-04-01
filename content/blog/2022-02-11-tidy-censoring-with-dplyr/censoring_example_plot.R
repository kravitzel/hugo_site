make_censoring_plot = function() {
  
  df = tibble(
    ID = paste0("P", seq(1, 5)),
    t = c(5, 3, 5, 2, 5),
    censored = factor(c("event", "event", "censor", "event", "censor"), 
                      levels = c("event", "censor"))
  )
  
  
  event_color = c(event = "firebrick2", censor = "goldenrod2")
  
  
  ggplot(df, aes(x = ID)) +
    # Censoring line 
    geom_hline(
      yintercept = 5,
      linetype = "dashed"
    ) + 
    # Plot people with events -----------------------------------
  geom_segment( # Red line segment
    data = filter(df, censored == "event"),
    mapping = aes(x = ID, y = 0, xend = ID,  yend = t),
    size = 1.5,
    color = event_color[["event"]]
  ) +
    geom_point( # Red X's for event times
      data = filter(df, censored == "event"),
      mapping = aes(x = ID, y = t),
      color = event_color[["event"]],
      shape = 4, # X as shape
      stroke = 2
    ) + 
    # Plot censored people -----------------------------------------
  geom_segment( # Red line segment
    data = filter(df, censored == "censor"),
    mapping = aes(x = ID, y = 0, xend = ID,  yend = t),
    color = event_color[["censor"]],
    size = 1.5
  ) + 
    geom_point( # Red X's for event times
      data = filter(df, censored == "censor"),
      mapping = aes(x = ID, y = t),
      color = event_color[["censor"]],
      shape = 17, # triangle as shape
      size = 4,
    ) + 
    labs(
      x = element_blank(),
      y = element_blank()
    ) + 
    coord_flip(
      ylim = c(0, 6),
    ) +
    theme_minimal() + 
    theme(
      axis.title.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.x = element_blank(),
      axis.title.y = element_blank(),
      axis.ticks.y = element_blank()
    ) 
}