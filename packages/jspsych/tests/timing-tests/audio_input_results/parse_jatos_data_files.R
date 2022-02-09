library(jsonlite)
library(base64enc)
source('parseJSONdata.R')

root <- getwd()
directory <- "raw_data"
output_directory <- "parsed_data"
filenames <- list.files(paste(root, '/', directory, sep=""), 
              pattern = '.txt', all.files = FALSE,
              full.names = FALSE, recursive = TRUE,
              ignore.case = FALSE, include.dirs = TRUE, no.. = FALSE)

for (i in 1:length(filenames)) {
  # read data
  data_file <- file(paste(root, '/', directory, '/', filenames[i], sep=""), open = "r")
  raw_data <- readLines(data_file, warn = FALSE)
  close(data_file)
  all_data <- parseJSONdata(raw_data, numComponents=1, isJsonStr=TRUE, id=as.character(i), returnResults=TRUE, saveToFile=FALSE)
  
  # remove the audio data from audio check trials 
  all_data$response[all_data$task == "audio_check"] <- NA 
  
  # parse the survey-text responses (TO DO: fix parsing function)
  start_responses_string <- all_data$response[1]
  start_responses <- strsplit(start_responses_string,',')
  all_data$n_trials <- start_responses[[1]][1]
  all_data$buffer_length <- start_responses[[1]][2]
  all_data$browser <- start_responses[[1]][3]
  all_data$device_os <- start_responses[[1]][4]
  all_data$intended_rt <- start_responses[[1]][5]
  
  # save parsed data
  id <- unique(all_data$jatos_result_ID)
  dir.create(paste(output_directory, "/", id, sep=""))
  write.csv(all_data, paste(output_directory, "/", id, "/result_", id, ".csv", sep=""), row.names=FALSE)
  
  # loop through the trials and convert base 64 data to audio (webm)
  trial_data <- subset(all_data, task == "trial")
  trial_count <- 0
  for (j in 1:nrow(trial_data)) {
    decoded <- base64decode(trial_data$response[j])
    if (!is.na(trial_data$response[j])) {
      trial_count <- trial_count+1
      aud_file <- file(paste(output_directory, "/", id, "/", trial_count, ".webm", sep=""),"wb")
      writeBin(decoded, aud_file)
      close(aud_file)
    }
  }
  
}