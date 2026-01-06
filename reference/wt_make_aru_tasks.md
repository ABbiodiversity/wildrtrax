# Linking media to WildTrax

`wt_make_aru_tasks()` uses a
[`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md)
input tibble to create a task template to upload to a WildTrax project.

## Usage

``` r
wt_make_aru_tasks(
  input,
  output = NULL,
  task_method = c("1SPM", "1SPT", "None"),
  task_length
)
```

## Arguments

- input:

  Character; An input
  [`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md)
  tibble. If not a
  [`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md)
  tibble, the data must contain at minimum the location,
  recording_date_time and file_path as columns.

- output:

  Character; Path where the output task csv file will be stored

- task_method:

  Character; Method type of the task. Options are 1SPM, 1SPT and None.

- task_length:

  Numeric; Task length in seconds. Must be between 1 - 1800 and can be
  up to two decimal places.

## Value

A csv formatted as a WildTrax task template

## Details

The following suite of functions will help you wrangle media and data
together in order to upload them to WildTrax. You can make
tasks(https://www.wildtrax.ca/home/resources/guide/projects/aru-projects.html)
and
tags(https://www.wildtrax.ca/home/resources/guide/acoustic-data/acoustic-tagging-methods.html)
using the results from a
[`wt_audio_scanner()`](https://abbiodiversity.github.io/wildrtrax/reference/wt_audio_scanner.md)
tibble or the hits from one of two Wildlife Acoustics programs
Songscope() and Kaleidoscpe().

## Examples

``` r
if (FALSE) { # \dontrun{
wt_make_tasks(input = my_audio_tibble, output = tasks.csv, task_method = "1SPT", task_length = 180)
} # }
```
