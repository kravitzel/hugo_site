library(tidyverse)
library(tidybayes)
library(distributional)

# Fixed effects plot ---------------------
set.seed(1)
plotting_df = tibble(
  study = c("True Effect", paste("Study", 1:4)),
  true_val = 0, 
  # observed_effect = c(0, 0.5, -0.4, 1, -1.1),
  sd = c(0, 0.10, 0.35, 0.20, 0.45)
) %>% 
  mutate(
    study = factor(study, c("True Effect", paste("Study", 1:4))) # Doesn't control order
  ) %>%
  mutate(
    observed_effect = map_dbl(sd, ~ rnorm(1, true_val, .x))
  )

plotting_df2 = tibble(
  type = rep(c("Overall Effect", "Observed Effect"), times = c(1, 4)),
  study = c("True Effect", paste("Study", 1:4)),
  val = plotting_df$observed_effect
)

ggplot() + 
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    alpha = 0.35
  ) + 
  stat_dist_slab(
    data = filter(plotting_df, study != "True Effect"),
    aes(y = study, 
        dist = "norm",
        arg1 = observed_effect,
        arg2 = sd),
    alpha = 0.5,
    fill = "skyblue",
  ) + 
  geom_point(
    data = plotting_df2,
    aes(x = val, y = study,  shape = type, color = type),
    size = 3,
  ) +
  scale_color_manual(
    values = c("black", "skyblue")
  ) +
  labs(
    x = element_blank(),
    y = element_blank(),
  ) + 
  theme_classic() +
  scale_x_continuous(limits = c(-2, 2)) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    legend.title = element_blank()
  ) 


# Random effects plot --------------------
set.seed(1)
plotting_df_re = tibble(
  study = c("Overall Effect", paste("Study", 1:4)),
  true_val = c(0, 0.1, -0.1, 0.3, -0.05),
  # observed_effect = c(0, 0.5, -0.4, 1, -1.1),
  sd = c(0, 0.10, 0.35, 0.20, 0.45)
) %>% 
  mutate(
    study = factor(study, c("True Effect", paste("Study", 1:4))) # Doesn't control order
  ) %>%
  mutate(
    observed_effect = map2_dbl(true_val, sd, ~ rnorm(1, .x, .y))
  )

plotting_df_re %>%
  select(-sd) %>% 
  pivot_longer(
    cols = c(true_val, observed_effect),
    names_to = "names"
  ) %>% 
  mutate(
    names = ifelse()
  )
  
  plotting_df2 = tibble(
    type = rep(c("Overall Effect", "Observed Effect"), times = c(1, 4)),
    study = c("True Effect", paste("Study", 1:4)),
    val = plotting_df$observed_effect
  )