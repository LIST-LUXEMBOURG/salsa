%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% © 2022 Luxembourg Institute of Science and Technology. All Rights Reserved.
% Author: Mohammad Afhamisis @LIST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
clc
format long

tic
disp('Initializing ...')
%% declaration and initials
import java.util.TimeZone

%suppose  "ToA=2.7935s" + "Gaurd_Time=20ms"
ToA=2.7935;
Gaurd_Time=0.020;
ToA_t=ToA+Gaurd_Time; % based on the location of each ed
Duty_Cycle=1;%

inp = input('Please enter the number of end devices:');  
while (isnumeric(inp) == false)
            disp('It is not a number. Wrong entry')
            inp = input('Please enter the number of end devices:'); 
end
number_of_ed=inp;

% other initial variables
counter=zeros(number_of_ed,3);
overall_mat=zeros(25,8);
cnt=0;
id_cnt=0;

disp('Reading the files, converting to array and creating visibility time tables ...')

%% reading files, converting them to array (in utc human-readable format) and create visibility timetable (to store utc epoch format)
for i=1:number_of_ed
    % creating the inputs from files
    eval(['x' num2str(i) '=readtable("cdata/' num2str(i) '.txt");'])
    % converting table to array
    eval(['x' num2str(i) '=x' num2str(i) '{:,:};'])
    % create two column table for visibility each time timetable
    eval(['dt_x' num2str(i) '=zeros(size(x' num2str(i) ',1)/3,2);'])
end

disp('Converting timetables to utc epoch format ...')

%% conversion from human-readable format to utc epoch format
for j=1:number_of_ed
            ex=eval(['x' num2str(j)]);
            es=size(ex,1);
            ed=eval(['dt_x' num2str(j)]);
            for i=1:es/3
                 ds=datestr(ex(3*(i-1)+1,:));
                 dt = datetime(ds,'TimeZone','utc');
                 eval(['dt_x' num2str(j) '(' num2str(i) ',1)=posixtime(dt);'])

                 ds=datestr(ex(3*(i-1)+3,:));
                 dt = datetime(ds,'TimeZone','utc');
                 eval(['dt_x' num2str(j) '(' num2str(i) ',2)=posixtime(dt);']) 
            end
end

disp('Creating the main matrix ...')

%% creating the main matrix "overall_mat"
for i=1:number_of_ed
    id_cnt=id_cnt+1;
    eval(['s=size(dt_x' num2str(i) ',1);'])
    eval(['overall_mat(cnt+1:cnt+s,1:2)=dt_x' num2str(i) ';'])
    eval(['overall_mat(cnt+1:cnt+s,3)=id_cnt;']) 
    cnt=cnt+s;
end

disp('Sorting based on the time ...')

%% sorting based on their timing (order: see the satellite earlier)
overall_mat=sortrows(overall_mat);
for i=1:size(overall_mat,1)
    overall_mat(i,4)=i;
end

disp('Implementing the scheduled traffic every 30 mins ...')

disp('--> creating epoch times of their offset')
%% Technique
% First: Create epoch time for the first TX of each end device
epoch_mat=zeros(number_of_ed,1);
date_initial=[2021 10 1 0 0 1];
date_initial_dt=datetime(date_initial,'TimeZone','utc');
epoch_initial=posixtime(date_initial_dt);

date_end=[2021 11 1 0 0 1];
date_end_dt=datetime(date_end,'TimeZone','utc');
epoch_end=posixtime(date_end_dt);

rng('shuffle')

for i=1:number_of_ed
    epoch_mat(i,1)=floor(rand*number_of_ed*100)+epoch_initial;
end

disp('--> generating TXs each 30 minutes...')

% Previous technique
TX_schedule=zeros(number_of_ed,2);
time_step=30*60;

for i=1:number_of_ed
    time_left_for_ed=epoch_end-epoch_mat(i,1);
    tx_chances=floor(time_left_for_ed/(time_step));
    for j=1:tx_chances
        TX_schedule(i,1)=epoch_mat(i,1)+(j-1)*(time_step);
        TX_schedule(i,2)=TX_schedule(i,1)+ToA_t;
        
        A=TX_schedule(i,1);
        B=TX_schedule(i,2);

        find_vis=find(overall_mat(:,3)==i);
        drop=1;
        for k=1:size(find_vis,1)
            C=overall_mat(find_vis(k),1);
            D=overall_mat(find_vis(k),2);
            
            if (A>=C & B<=D)
                counter(i,1)=counter(i,1)+1;
                overall_mat(find_vis(k),5)=A;
                overall_mat(find_vis(k),6)=B;
                drop=0;
            end
        end
        if drop==1
            counter(i,2)=counter(i,2)+1;
        end
    end
end
%%%%% check collisions
disp('--> Checking for collisions ...')
for i=1:size(overall_mat(:,:),1)
    A=overall_mat(i,5);
    B=overall_mat(i,6);
    if (A~=0) % or B~=0
        for j=1:size(overall_mat(:,:),1)
            if (i~=j)
                C=overall_mat(j,5);
                D=overall_mat(j,6);
                if (A<D & B>C)
                    % then we have conflict
                    overall_mat(i,7)=1;
                    overall_mat(j,7)=1;
                end
            end
        end
    end
end
for i=1:number_of_ed
    counter(i,3)=sum(overall_mat(find(overall_mat(:,3)==i),7));
end
counter(:,1)=counter(:,1)-counter(:,3);

disp('--> Finished ....')

disp('Total Collisions: ')
size(find(overall_mat(:,7)==1),1)

disp('Total Drops: ')
sum(counter(:,2))

disp('Total Success: ')
sum(counter(:,1))

disp('Performance (in %): ')
(sum(counter(:,1))/(sum(counter(:,2))+sum(counter(:,1))+size(find(overall_mat(:,7)==1),1)))*100
toc
