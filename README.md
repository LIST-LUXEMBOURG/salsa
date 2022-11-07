# LORSAT
LORSAT (Design of LoRaWAN protocol Optimisation over SATellite Connection for precision agriculture applications) is a national research project funded by the Luxembourg National Research Fund under the FNR CORE 2019 framework. LORSAT was kicked-off in September 2020 to develop technical solutions that allow the smooth integration and interoperability of satellite and LoRaWAN networks, while ensuring the target Quality of Service (QoS), over the entire end-to-end (e2e) system.

# Project Website:
https://www.lorsat.lu/

# 1) How to use:
In this repository, there are two main parts. 
## SatelliteFly.py 
Python based Position and visibility generator
This module provides you the ability of generating desired random locations in your preferred locations. Then, It will produce visibility times of specific satellites for those locations. The output of this module will be ready to use in the Matlab modules.

## Matlab modules
There are three main matlab modules.
- Scheduled_Traffic: Creates scheduled traffics over a known period.
- SALSA_FCFS: Implements First Come First Serve (FCFS) scheduling method.
- SALSA_FAIR: Implements FAIR scheduling method.

# 2) How to install:
- For MATLAB modules, you need to use a MATLAB compiler.
- For Python, you need to install GEOPY, SKYFIELD and PANDAS libraries. Please check their official websites to execute the right installation.

# Citation:
This work is published online under the Luxembourg Institute of Science and Technology (LIST) copyright. Please follow the LIST copyright.
These codes have been used to demonstrate and simulate the results of our paper "SALSA: A Scheduling Algorithm for LoRa to LEO Satellites
", DOI: https://doi.org/10.1109/ACCESS.2022.3146021   
Please use this format to cite:
"M. Afhamisis and M. R. Palattella, "SALSA: A Scheduling Algorithm for LoRa to LEO Satellites," in IEEE Access, vol. 10, pp. 11608-11615, 2022, doi: 10.1109/ACCESS.2022.3146021."
