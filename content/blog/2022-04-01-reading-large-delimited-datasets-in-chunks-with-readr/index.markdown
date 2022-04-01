---
title: Reading large delimited datasets in chunks with readr
author: ''
date: '2022-04-01'
slug: []
categories: []
tags: []
---


<!-- I recently had to work with several large CSV files, ranging in size from 8Gb to 12Gb. I had a pretty straightforward requirement: I needed to `dplyr::group_by()` a categorical variable and count the number of unique records with `dplyr::n_distinct()`.  I ran out of RAM whenever I loaded the entire dataset into R with `readr::read_csv()` or `data.table::fread()`.  I tried to load the data in chunks (see more below), but found the existing documentation to be confusing and piecemeal. I've provided a system that works for me in the blog post. -->

## What is chunking?

Sometimes you have a dataset that's too large to fit in memory.  One way to get around this is to divide your data into subsets ("chunks") that do fit into memory and process each chunk separately. You can aggregate the processed chunks together after you've reduced the size. This is basically a low-tech implementation of the [MapReduce](https://en.wikipedia.org/wiki/MapReduce#Overview) framework used [Apache Hadoop](https://www.ibm.com/cloud/blog/hadoop-vs-spark)

## Chunks in readr

You can read deliminated data in chunks by using any of the  [`read_*_chunked()` functions](https://readr.tidyverse.org/reference/read_delim_chunked.html) from the [`readr` package](https://readr.tidyverse.org/index.html). I'll focus on `read_csv_chunked()`. I'll use a CSV version of the mtcars





## Why didn't you use XYZ?

Why didn't *you* use XYZ?
