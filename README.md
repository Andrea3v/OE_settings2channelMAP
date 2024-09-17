# OE_settings2channelMAP
Open Ephys settings.xml file to channel map used by Kilosort

Script reads the relevant probe parameters from the 'settings_*.xml' file 
creates channel maps as .json and .mat 

$ INPUT: 'settings.xml' from Open ephys recording
$ OUTPUT: channel map as .json and .mat files, figure of the probe channel map

% tested on Neuropixels 1.0 and 2.0 probes, Open Ephys v0.6.7
