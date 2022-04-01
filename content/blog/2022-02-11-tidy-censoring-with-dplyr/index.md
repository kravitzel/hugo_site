---
title: "2022 02 11 Tidy Censoring With dplyr"
subtitle: ""
excerpt: ""
date: 2022-02-11T09:21:56-05:00
author: "Eli Kravitz"
draft: true
series:
tags:
categories:
layout: single # single or single-sidebar
---
<script src="{{< blogdown/postref >}}index_files/kePrint/kePrint.js"></script>
<link href="{{< blogdown/postref >}}index_files/lightable/lightable.css" rel="stylesheet" />



This post will give guidance for simulating survival times with censoring. We'll cover Type II censoring ("administrative" censoring) and right censoring.

# Simulating Data

## Survival Times
We'll simulate hypothetical data from a two arm clinical trial with a time-to-event endpoint. A total of 1000 patients are randomized 1:1 to each arm.

Denote the `\(i^{th}\)` survival times with `\(T_{i}\)` . Let `\(X_i\)` denote assignment to the treatment arm. So `\(X_i = 0\)` if subject `\(i\)` is assigned to the control arm and `\(X_i = 1\)` if a subject is assigned to the treatment arm. We'll assume that survival times for all patients follow an exponential distribution with hazard function `\(h(t_i) = \lambda \cdot \exp(\beta X_i)\)`, where `\(\beta\)` is the log-hazard ratio (treatment effect) between the two arms.

We'll assume patients on the control arm have a median time-to-event of 10 months. This corresponds `\(\lambda = \frac{\log2}{10}\)` in the model above. Assume the treatment doubles survival time, with a corresponding hazard ratio of `\(exp(\beta) = 0.50\)`.


```r
set.seed(123)
lambda <- log(2) / 10
hr <- 0.50
n_per_arm <- 500

patient_df <- tibble(
  patient_id = seq(1, 2 * n_per_arm),
  arm = rep(c("ctrl", "trt"), each = n_per_arm),
  surv_time = c(rexp(n_per_arm, log(2) / 10), rexp(n_per_arm, log(2) / 10 * hr))
)
```

Let's make sure our simulated data matches our expectation. The median survival is what we expect for both arms. 


```r
patient_df %>% 
  group_by(arm) %>%
  summarize("Median Survival" = median(surv_time)) %>%
  kableExtra::kbl(digits = 1) %>%
  kable_paper("hover", full_width = F)
```

<table class=" lightable-paper lightable-hover" style='font-family: "Arial Narrow", arial, helvetica, sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
 <thead>
  <tr>
   <th style="text-align:left;"> arm </th>
   <th style="text-align:right;"> Median Survival </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> ctrl </td>
   <td style="text-align:right;"> 10.5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trt </td>
   <td style="text-align:right;"> 21.1 </td>
  </tr>
</tbody>
</table>

Let's plot both arms to get an idea of what the distribution looks like.



## Type II Censoring

An experiment may end when a prespecified number of events occur. All subjects without a survival event are right censored. This is called right censoring.  

<div class="figure">
<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-1-1.png" alt="Type II Censoring" width="672" />
<p class="caption">Figure 1: Type II Censoring</p>
</div>


In our example, we'll stop the trial when we've observed that `\(80\%\)` of patients have had an event. This corresponds to 800 events. The remaining 200 will be censored

In `dplyr`, we can use `nth()` function to find the time when the experiment ends. Then we use `ifelse()` to replace censored survival time with the time the experiment ends.


```r
censor_time <- nth(patient_df$surv_time, n = 800L, order_by = patient_df$surv_time)

patient_df = patient_df %>%
  mutate(
    event = surv_time <= censor_time,
    obs_time = ifelse(!event, censor_time, surv_time),
  )
```

## Arrival Times and Censoring 

Patients don't begin a clinical trial at the same time. Their entry into the trial is staggered; the sponsor finds new sites and recruits new patients. It can take months or years to recruit patients. As we'll see, this affects censoring.

We'll assume that patients join the trial uniformally over a 6 month period: `\(A_i \sim U[0, 6]\)`. We add these arrival times to patient's survival times. This represents time relative to the start of the trial, when asubject will have an event.


```r
with_arrivals <-
  patient_df %>% 
  mutate(
    arrival_time = runif(n(), 0, 6),
    relative_time = arrival_time + surv_time
  )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/arrival_plot-1.png" width="672" />



<!-- Let's examine this on a subset of our data -->
<!-- ```{r arrival-times-preview, echo=FALSE} -->
<!-- set.seed(1) -->
<!-- with_arrivals %>%  -->
<!--   sample_n(5) %>%  -->
<!--   select(patient_id, arrival_time, surv_time, relative_time) %>%  -->
<!--   kbl(digits = 1) %>%  -->
<!--   kable_paper("hover", full_width = F) -->
<!-- ``` -->


## Arrival Times and Censoring Type II ("Administrative") Censoring

We'll use the tools from the previous section to the time of censoring with arrivals. We find the calendar time when800 events occur

We can get the time of the 400th event with `nth(relative_time, n = 400, order_by = relative_time) = ` 13.7


```r
censor_time = with(with_arrivals, nth(relative_time, n = 400, order_by = relative_time))

  
with_arrivals %>% 
  mutate(
    event = relative_time <= censor_time,
    obs_time = ifelse(!event, censor_time - arrival_time, surv_time),
  )
```

```
## # A tibble: 1,000 x 7
##    patient_id arm   surv_time event obs_time arrival_time relative_time
##         <int> <chr>     <dbl> <lgl>    <dbl>        <dbl>         <dbl>
##  1          1 ctrl     12.2   FALSE   10.0          3.67          15.8 
##  2          2 ctrl      8.32  TRUE     8.32         3.35          11.7 
##  3          3 ctrl     19.2   FALSE   13.5          0.240         19.4 
##  4          4 ctrl      0.456 TRUE     0.456        4.47           4.93
##  5          5 ctrl      0.811 TRUE     0.811        1.24           2.05
##  6          6 ctrl      4.57  TRUE     4.57         3.94           8.51
##  7          7 ctrl      4.53  TRUE     4.53         3.13           7.67
##  8          8 ctrl      2.10  TRUE     2.10         3.80           5.90
##  9          9 ctrl     39.3   FALSE    9.99         3.71          43.0 
## 10         10 ctrl      0.421 TRUE     0.421        1.71           2.13
## # ... with 990 more rows
```




