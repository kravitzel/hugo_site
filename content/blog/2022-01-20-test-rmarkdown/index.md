---
title: "2022 01 20 Test Rmarkdown"
subtitle: ""
excerpt: ""
date: 2022-01-20T17:13:29-05:00
author: ""
draft: true
series:
tags:
categories:
layout: single # single or single-sidebar
---

Let's see if this works


```r
set.seed(3)
hist(rnorm(100))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-1-1.png" width="672" />


```r
library(tidyverse)

mtcars %>% 
  rownames_to_column(var ="car") %>% 
  as_tibble() %>% 
  filter(str_detect(car, "Mazda")) %>% 
  knitr::kable()
```



|car           | mpg| cyl| disp|  hp| drat|    wt|  qsec| vs| am| gear| carb|
|:-------------|---:|---:|----:|---:|----:|-----:|-----:|--:|--:|----:|----:|
|Mazda RX4     |  21|   6|  160| 110|  3.9| 2.620| 16.46|  0|  1|    4|    4|
|Mazda RX4 Wag |  21|   6|  160| 110|  3.9| 2.875| 17.02|  0|  1|    4|    4|

