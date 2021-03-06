# AOMI tidydata

library(signal)
library(edf)
library(dplyr)
library(tidyr)

# Import EDF file
#folder_dir = "C:/Users/Paul/EDF Files/"                      # LG.29 PC
folder_dir = "C:/Users/mnpdeb/AOMI_EDF/"                      # Ada Laptop

for (i in 1:17)
{
  # Generate tidy df
  aomi_tidy <- data.frame()[,]
  
  files_no <- readline(prompt = "How many files? ")
  p_code <- readline(prompt = "Enter participant number (e.g. 1): ")
  
  for (i in 1:files_no)                                
  {
    day <- readline(prompt = "Input day of session (e.g. 1): ")
    filename <- paste(folder_dir, p_code, "_s", day, ".edf", sep = "")
    
    import_eeg <- read.edf(filename, read.annotations = TRUE, header.only = FALSE)
    
    # construct main data frame for EEG anaylsis
    raw_eeg <- data.frame()
    
    t = data.frame(import_eeg$signal$C3$t)
    raw_eeg <- cbind(t)
    names(raw_eeg)[1] <- "Timestamp"
    
    C3 = data.frame(import_eeg$signal$C3$data)
    raw_eeg <- cbind(raw_eeg, C3)
    names(raw_eeg)[2] <- "C3"
    
    C4 = data.frame(import_eeg$signal$C4$data)
    raw_eeg <- cbind(raw_eeg, C4)
    names(raw_eeg)[3] <- "C4"
    
    CP5 = data.frame(import_eeg$signal$CP5$data)
    raw_eeg <- cbind(raw_eeg, CP5)
    names(raw_eeg)[4] <- "CP5"
    
    CP6 = data.frame(import_eeg$signal$CP6$data)
    raw_eeg <- cbind(raw_eeg, CP6)
    names(raw_eeg)[5] <- "CP6"
    
    C1 = data.frame(import_eeg$signal$C1$data)
    raw_eeg <- cbind(raw_eeg, C1)
    names(raw_eeg)[6] <- "C1"
    
    C2 = data.frame(import_eeg$signal$C2$data)
    raw_eeg <- cbind(raw_eeg, C2)
    names(raw_eeg)[7] <- "C2"
    
    FC5 = data.frame(import_eeg$signal$FC5$data)
    raw_eeg <- cbind(raw_eeg, FC5)
    names(raw_eeg)[8] <- "FC5"
    
    FC6 = data.frame(import_eeg$signal$FC6$data)
    raw_eeg <- cbind(raw_eeg, FC6)
    names(raw_eeg)[9] <- "FC6"
    
    raw_eeg
    
    # Markers in a separate data frame
    markers <- data.frame()
    
    tm = data.frame(import_eeg$events$onset)
    markers <- cbind(tm)
    names(markers)[1] <- "tm"
    
    trigger = data.frame(import_eeg$events$annotation)
    markers <- cbind(markers, trigger)
    names(markers)[2] <- "trigger"
    markers$trigger <- as.numeric(markers$trigger)
    within(markers, levels(trigger)[levels(trigger) == "Trigger#1"] <- "1")
    markers$trigger = markers$trigger - 1
    markers
    
    markers_reduced <- dplyr::filter(markers, trigger > 2 & trigger < 5, tm >30) # tm>50 to select markers at session start 
    markers_reduced
    markers_left <- dplyr::filter(markers_reduced, trigger == 3)
    markers_left
    markers_right <- dplyr::filter(markers_reduced, trigger == 4)
    markers_right
    markers_reduced$trigger <- as.factor(markers_reduced$trigger)
    
    
    # Time-based Epoching
    
    #Initialisation
    sampling_frequency = 500 #Hertz
    epoch_length = 12.4 #seconds
    epoch_starting = -3.5 # at which point?
    
    epoch_samples = (sampling_frequency * epoch_length)
    Time <- seq(from = epoch_starting, to = epoch_starting+epoch_length, length.out = epoch_samples)
    Time <- round(Time, digits = 3)
    Time <- data.frame(Time)
    
    # All the trials -- change trial in settings
    all_trial_signals1 <- data.frame()[1:epoch_samples, ]
    PID <- data.frame(list(rep(as.numeric(p_code), epoch_samples)))
    names(PID)[1] <- "PID"
    sesh <- data.frame(list(rep(as.numeric(day), epoch_samples)))
    names(sesh)[1] <- "Session"
    
    # LEFT TRIALS
    class <- data.frame(list(rep("Left", epoch_samples)))
    names(class)[1] <- "Class"
    epoch_counter = 1
    
    for (i in 1:20)
    {
      epoch_x <- data.frame()
      epoch_start = markers_left$tm[epoch_counter]+epoch_starting # -- change trial in settings
      epoch_end = epoch_start + epoch_length
      epoch_start_i = which(round(raw_eeg$Timestamp, 3) == round(epoch_start, 3))
      epoch_end_i = epoch_start_i + epoch_samples-1
      trial_no <- data.frame(list(rep(as.numeric(epoch_counter), epoch_samples)))
      names(trial_no)[1] <- "Trial"
      epoch_x <- raw_eeg[epoch_start_i:epoch_end_i,]
      epoch_x <- data.frame(epoch_x)
      epoch_x <- cbind(PID, sesh, epoch_x[1], trial_no, class, Time, epoch_x[2:8])
      all_trial_signals1 <- rbind(all_trial_signals1, epoch_x)
      epoch_counter = epoch_counter + 1
    }
    
    # RIGHT TRIALS
    class <- data.frame(list(rep("Right", epoch_samples)))
    names(class)[1] <- "Class"
    epoch_counter = 1
    
    for (i in 1:20) 
    {
      epoch_x <- data.frame()
      epoch_start = markers_right$tm[epoch_counter]+epoch_starting # -- change trial in settings
      epoch_end = epoch_start + epoch_length
      epoch_start_i = which(round(raw_eeg$Timestamp, 3) == round(epoch_start, 3))
      epoch_end_i = epoch_start_i + epoch_samples-1
      trial_no <- data.frame(list(rep(as.numeric(epoch_counter), epoch_samples)))
      names(trial_no)[1] <- "Trial"
      epoch_x <- raw_eeg[epoch_start_i:epoch_end_i,]
      epoch_x <- data.frame(epoch_x)
      epoch_x <- cbind(PID, sesh, epoch_x[1], trial_no, class, Time, epoch_x[2:8])
      all_trial_signals1 <- rbind(all_trial_signals1, epoch_x)
      epoch_counter = epoch_counter + 1
    }
    
    all_trial_signals1 <- all_trial_signals1 %>% arrange(Timestamp)
    
    rename_trial = 1
    rename_start = 1
    rename_end = epoch_samples
    
    for (i in 1:40)
    {
      all_trial_signals1$Trial[rename_start:rename_end] <- rename_trial
      rename_trial = rename_trial + 1
      rename_start = rename_start + epoch_samples
      rename_end = rename_end + epoch_samples
    }
    
    aomi_tidy <- rbind(aomi_tidy, all_trial_signals1)
    
  }
  
  
  # Save EEG data per participant as CSV file
  write.table(aomi_tidy, file = sprintf("AOMI_%s_org.csv", p_code), sep = ",", row.names = FALSE)
  
}



