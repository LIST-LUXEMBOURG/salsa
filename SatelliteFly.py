##############################################################################
# © 2022 Luxembourg Institute of Science and Technology. All Rights Reserved.
# Author: Mohammad Afhamisis @LIST
##############################################################################


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Libraries, Imports and general variables
# ================================================================
from skyfield.api import load, wgs84
from geopy.geocoders import Nominatim 
from random import uniform 

import time
import pandas as pd 

counter=0
app=Nominatim(user_agent="JournalDEv")

# Selecting visibility check period
ts=load.timescale()
t0=ts.utc(2021,10,1)
t1=ts.utc(2021,10,30)
satname='LACUNASAT-3'
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# (1) Generating Positions on a selected area using uniform dist
# ================================================================
specific_list=['Lëtzebuerg']
country_list=['Lëtzebuerg','France','Deutschland','España','Portugal','Italia','Schweiz/Suisse/Svizzera/Svizra','België / Belgique / Belgien','Nederland','Österreich','Česko','Polska']
europe_list=['Lëtzebuerg','France','Deutschland','España','Portugal','Italia','Schweiz/Suisse/Svizzera/Svizra','België / Belgique / Belgien','Nederland','Österreich','Česko','Polska']
answer_list=[] 

while counter<1000:
  x,y=uniform(49.44,50.18),uniform(5.73,6.53)
  try:
    location=app.reverse(str(x)+","+str(y), timeout=None)
    time.sleep(1)
    if location !=None:
      address=location.raw['address']
      country=address.get('country',"")
      c=country;
      if c in specific_list:
        print(str(x)+","+str(y))
        counter+=1
        with open('positions.txt','a') as file_object:
          print(str(x)+","+str(y),file=file_object)
          if c in europe_list:
            with open('regions.txt','a') as file_object2:
              print('EU,',counter,file=file_object2)
  except Exception as error:
       pass
  else:
       pass
  finally:
       pass
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# (2) Generating Satellite visibilites based on the positions
# ================================================================

# reading active satellites, then selecting our target satellite for check
station_url='https://www.celestrak.com/norad/elements/active.txt'
stations=load.tle_file(station_url)
by_name={sat.name: sat for sat in stations}
satellite=by_name[satname] 

# Printing the satelite data to validate it is working
print('Loaded ',len(stations),'satellites')
print(satellite)
print(satellite.epoch.utc_jpl)

# we have derived locations of the devices in one file, lat and long format
# we have to read and check the visibility over a specific elevation and duration
lines = [] 
with open('positions.txt') as f:
  # reading positions line by line in the file
  lines = f.readlines()
  # using a counter variable to number the generated files
  count = 0
  for line in lines:
    # our point on the earth
    currentline=line.split(",")
    lat=float(currentline[0])
    lon=float(currentline[1])
    bluffton=wgs84.latlon(lat,lon)
    # check the visibility for this point in this duration for this elevation
    t,events=satellite.find_events(bluffton,t0,t1,altitude_degrees=30.0)
    count += 1
    for ti,event in zip(t,events):
      # we can add some text after the visibility times in the lines, but we leave it blank
      # the output of find_events are 3 lines per each visibility, rise, high, set
      name=('','','')[event]
      # print the output to visually check output
      print(ti.utc_strftime('%Y %m %d %H %M %S'),name)
      # creating a file name and then write to file (append)
      outputname= '/home/mafhamisis/VisData/'+ str(count) + '.txt'
      with open(outputname,'a') as file_object:
        print(ti.utc_strftime('%Y %m %d %H %M %S'),name,file=file_object)
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
