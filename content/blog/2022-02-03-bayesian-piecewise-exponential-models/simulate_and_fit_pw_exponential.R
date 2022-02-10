# Libraries -----------------------------
library(tidyverse)
library(survival)
library(PWEALL)

# Parameters --------------------------------
rate_1_ctrl <- -log(0.60)/ 24 # 60% DFS rate at 24 months
rate_2_ctrl <- log(2) / 10 # Filler rate

hr_1 <- 0.43 
hr_2 <- 0.31

rate_1_trt = hr_1 * rate_1_ctrl
rate_2_trt = hr_2 * rate_2_ctrl

n_trt = 1e3 # Big sample size to confirm our model estimates parameters correctly
n_ctrl = 1e3# Big sample size to confirm our model estimates parameters correctly

change_point = 24 # place where hazard changes. Around 24 months

# Simulate survival times -----------------------------------------------------
ctrl_time = rpwe(nr = n_ctrl, rate = c(rate_1_ctrl, rate_2_ctrl), tchange = c(0,change_point))$r
trt_time = rpwe(nr = n_trt, rate = c(rate_1_trt, rate_2_trt), tchange = c(0,change_point))$r

all_data = tibble(
  "id" = seq(1, n_trt + n_ctrl),
  "time" = c(ctrl_time, trt_time),
  "trt" = c(rep(0, n_ctrl), rep(1, n_trt)),
  "event" = 1 # everyone has an event, replace with censoring in actual data
)

# Fit model -------------------------------------------------------------------
# Piecewise exponential model needs to be fit as a Poisson model with an offset.
# You can ignore why this works if you want. References are below
#     Math explained: https://data.princeton.edu/wws509/notes/c7s4
#     Code explained: https://data.princeton.edu/wws509/r/recidivism

# Put survival data into subrecord format
survival_data <- survSplit(Surv(time, event) ~ trt,
                           id = "id",
                           start = "t_start",
                           end = "t_end",
                           cut = c(change_point),
                           episode = "interval",
                           data = all_data) %>% 
  mutate(exposure = t_end - t_start,
         interval = ifelse(interval == 1, "(0, 24]", ">24"))

# Fit Poisson equivalent model of piecewise exponential
fit = glm(event ~ offset(log(exposure)) + interval * trt - 1, 
          family = poisson, data = survival_data)


# Extract coefficients and parameterize in terms of hazards and hazard ratios ------------
estimated_rate1 <- exp(fit$coefficients[1])
estimated_rate2 <- exp(fit$coefficients[2])
estimated_hr1 <- exp(fit$coefficients[3])
estimated_hr2 <- exp(fit$coefficients[3] + fit$coefficients[4])
