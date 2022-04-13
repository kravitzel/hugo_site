---
title: "Reading large delimited datasets in chunks with readr"
subtitle: ""
excerpt: ""
date: 2022-04-13
author: "Eli S. Kravitz"
draft: false
series:
tags:
categories:
layout: single # single or single-sidebar
---

## Use Case

I recently had to work with several large CSV files, ranging in size from 8Gb to 12Gb. I needed to use `dplyr::group_by()` a categorical variable and count the number of unique records in each group with `dplyr::n_distinct()`.  I ran out of RAM whenever I loaded the entire dataset into R with `readr::read_csv()` or `data.table::fread()`.  I tried to load the data in chunks (see more below), but found the existing documentation to be confusing and piecemeal. I collected what I learned into this blog post.

## What is chunking?

Sometimes you have a dataset that's too large to fit in memory.  One way to get around this is to divide your data into subsets ("chunks") that do fit into memory and process each chunk separately. You can aggregate the processed chunks together after you've reduced the size. This is basically a low-tech implementation of the [MapReduce](https://en.wikipedia.org/wiki/MapReduce#Overview) framework used [Apache Hadoop](https://www.ibm.com/cloud/blog/hadoop-vs-spark)

## Chunks in readr

You can read deliminated data in chunks by using any of the  [`read_*_chunked()` functions](https://readr.tidyverse.org/reference/read_delim_chunked.html) from the [`readr` package](https://readr.tidyverse.org/index.html). I'll focus on `read_csv_chunked()` using a CSV file of the mtcars `dataset`.


`readr::read_csv_chunked()` requires at least two arguments:`read_csv_chunked(file, callback)`.  `file` is the file path of of your`.csv` file. The `calllback` argument is a little more complicated. The [documentation](https://readr.tidyverse.org/reference/callback.html#ref-examples) is sparse for this and [aimed at power-users](https://github.com/tidyverse/readr/issues/510#issuecomment-242363754).

Callbacks tell R what action to take after it finishes reading a data chunk into memory.  There are three classes of of callbacks that you're likely to use. Each callback applies a function `f()` to the chunk before returning a value. 

1. `DataFrameCallback` - Apply `f` to each chunk then combine results of `f(chunk)` by appending rows  into a `tibble`
    + Example: Read each chunk -> Remove records that don't meet a condition  --> append rows
2. `SideEffectChunkCallback` - Apply `f` to reach chunk and return nothing
    + Example: Reach each chunk --> write each chunk to a `.parquet ` file 
3. `AccumulateCallBack` - Calculates single result, carrying the value across chunks ("accumulate")
    + Example: Count the number of distinct IDs in each chunk --> add them together 

To use a callback in `read_csv_chunked` you first declare the function to apply to each chunk. The function must have the two arguments: `data` and `pos`. The `data` argument holds the current data chunk and `pos` (short for position) holds the line number that the current chunk begins on.   **You must include `pos` in your function arguments even if function does not use it.** If you use `AccumulateCallBack` you must include a third argument, `acc`, which stores the current value of their accumulator. You need to give a `acc` a default value in the function definition, for example `f = function(..., acc = NA)` or `f = function(..., acc = 0)`

The simple example below shows how read a `.csv` file in chunks with a custom callback function. We load `mtcars` in chunks and keep cars with manual transmission (`am == 0`) and miles/gallon over over 20 (`mpg >= 20`).


```r
library(readr)
library(dplyr)
# data(mtcars); write_csv(mtcars, "mtcars.csv")

# Function to pass to DataFrameCallback$new()
f = function(data, pos) {  # pos must be an  argument even though unused
  data %>% 
    filter(am == 0L, mpg >= 20)
}

chunked_df = read_csv_chunked(
  file = "mtcars.csv",
  callback = DataFrameCallback$new(f),
  chunk_size = 5L
)

chunked_df
```

```
## # A tibble: 4 x 11
##     mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
##   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
## 1  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
## 2  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
## 3  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
## 4  21.5     4  120.    97  3.7   2.46  20.0     1     0     3     1
```

## Why didn't you use XYZ?

*Why didn't **you** use XYZ?*

There are options for reading chunked data inside and outside of R. 

* Python's [`pandas.read_csv(..., chunksize)`](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html) returns an [iterator](https://wiki.python.org/moin/Iterator) to read a read a [CSV in chunks](https://pythonspeed.com/articles/chunking-pandas/). This is a good option if you're okay leaving the R and tidyverse ecosystem. 
* R's [`LaF` package](https://cran.r-project.org/web/packages/LaF/index.html)  offers fast, random access to ASCII files without loading the file into memory. `read_chunkwise()` from the [`chunked` package](https://cran.r-project.org/web/packages/chunked/index.html) is a wrapper that provides `dplyr` like synatx to `Laf`. I couldn't get either package to work, and I couldn't diagnose the problem from the error messages.
* `fread(...,)` from `data.table` can read files in chunks using the `skip` and `nrows` arguments. However, the user has to manually [program this functionality](https://stackoverflow.com/a/60085589/2838936). Things get complicated if you want to keep column names or apply a function to each chunk. 
