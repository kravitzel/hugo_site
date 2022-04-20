---
title: "2022 02 03 Bayesian Piecewise Exponential Models"
subtitle: ""
excerpt: ""
date: 2022-02-03T18:47:55-05:00
author: ""
draft: true
series:
tags:
categories:
layout: single # single or single-sidebar
---


## The Exponential Distribution 

<!-- The [Exponential Distribution](https://en.wikipedia.org/wiki/Exponential_distribution)  -->

An exponential survival model is considered the simplest [parametric survival model](https://data.princeton.edu/wws509/notes/c7.pdf). An exponential model assumes the risk of an event occurring remains constant over time. This results in the the hazard function
`$$h(t) = \lambda$$`
and the corresponding survival function given by
$$S(t) = \exp(-\lambda t) \text{ and } $$



## Why use an Exponential Model

An exponential survival model may seem overly simplistic. The assumptions are not realistic for most real world applications; an exponential model would say you have the same risk of death at 80 years old and 20 years old. Why then would anyone use the exponential distribution?

Well, sometimes, it works. On a short enough time scale the risk may be constant and only modified by covariates. If a medical treatment is given for 3 months, the risk of relapse may be constant. 

The median of the exponential distribution has a simple expression: `\(\frac{\log(2)}{\lambda}\)`. Say we don't have patient level data and we only know that the median overall survival time is 6 months. If we want to simulate what those patient-level survival times look like, our best guess would be to simulate them from an `\(Exp \Big(\frac{\log(2))}{6} \Big)\)`

## Piecewise Exponential Model

A piecewise exponential model is a flexible extension to the exponential model. We define `\(J\)` unique cutpoints `\(0 < \tau_1 < \tau_2 < \dots \tau_J = \infty\)` partition time into `\(J\)` disjoint. In each interval, we assume there is a constant hazard rate. In the `\(j^{th}\)` interval, defined by `\([\tau_{j-1}, \tau_j)\)`, the hazard is 
`$$h(t) = \lambda_j \text{ for } t \in [\tau_{j-1}, \tau_j)$$` 

There are always drawbacks. The difficulty of a piecewise exponential model is that you have to define the changepoints. There is some literature with mixed success (find sources) of estimate both the changepoints and the hazards.

There are two areas where piecewise exponential models are especially useful:
1. Modeling survival times when there is a known change in exposure. We'll look at an example where patients can switch treatments in a clinical trial
2. Approximating a complicated survival function. Think using regression splines 

### One Changepoint / Two Hazards

Say we're observing two groups of patients: a low risk group and a high risk group. We know from a previous study that low risk patients have a median survival time of 20 months and high risk patients have a median survival time of 10 months. 

After 6 months of the study, a new treatment is approved and all patients are given this treatment. We expect low-risk patients to have a 40% reduction in mortality, corresponding to a hazard ratio of 0.60. High-risk patients have a 50% reduction in mortality risk (hazard ratio of 0.5).

This is the perfect situation to use a piecewise exponential model. We'll break our time interval into `\([0, 6)\)` and `\([6, \infty]\)`. Our hazard an survival functions look like


<img src="{{< blogdown/postref >}}index_files/figure-html/two_hazard_pw-1.png" width="672" />

## Fitting a Piecewise Exponential with Stan


```r
library(PWEALL) # Simulates piecewise exponential
library(survival)

n_per_arm <- 10000
n_events <- 400
ctrl_rates = log(2) / c(15, 40) # Median surv time 15 months before change point, 40 after
trt_rates = log(2) / c(25, 80) # Median surv time 25 months before change point, 50 after

change_point = 15

# Simulate survival times -----------------------------------------------------
ctrl_time = rpwe(nr = n_per_arm, rate = ctrl_rates, tchange = c(0,changepoint))$r
trt_time = rpwe(nr = n_per_arm, rate = trt_rates, tchange = c(0,changepoint))$r

# all_data = tibble(
#   "id" = seq(1, 2 * n_per_arm),
#   "arm" = c(rep("ctrl", n_per_arm), rep("trt", n_per_arm)),
#   "true_time" = c(ctrl_time, trt_time)
# ) %>% 
#   mutate( # administrative censoring at 80$ events, (400 events)
#     "event" = if_else(true_time > nth(true_time, n_events, order_by = true_time), 0L, 1L),
#     "obs_time" = if_else(event == 1L, true_time, nth(true_time, n_events, order_by = true_time))
#     ) 

all_data = tibble(
  "id" = seq(1, 2 * n_per_arm),
  "arm" = c(rep("ctrl", n_per_arm), rep("trt", n_per_arm)),
  "time" = c(ctrl_time, trt_time),
  event = 1)

# Fit model -------------------------------------------------------------------
# Piecewise exponential model needs to be fit as a Poisson model with an offset.
# You can ignore why this works if you want. References are below
#     Math explained: https://data.princeton.edu/wws509/notes/c7s4
#     Code explained: https://data.princeton.edu/wws509/r/recidivism

# Put survival data into subrecord format
survival_data <- survSplit(Surv(time, event) ~ arm,
                           id = "id",
                           start = "t_start",
                           end = "t_end",
                           cut = c(change_point),
                           episode = "interval",
                           data = all_data) %>% 
  mutate(exposure = t_end - t_start,
         interval = ifelse(interval == 1, "[0, 20)", "[20, Inf)"))

# Fit Poisson equivalent model of piecewise exponential
fit = glm(event ~ offset(log(exposure)) + interval * arm - 1, 
          family = poisson, data = survival_data)

estimated_rate1 <- exp(fit$coefficients[1])
estimated_rate2 <- exp(fit$coefficients[2])
estimated_hr1 <- exp(fit$coefficients[3])
estimated_hr2 <- exp(fit$coefficients[3] + fit$coefficients[4])
exp(fit$coefficients[4])
```

```
## interval[20, Inf):armtrt 
##                0.7740605
```
