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

%suppose "ToA=2.7935s","Gaurd_Time=20ms", "51Bytes","125KHz"
ToA=2.7935;
Gaurd_Time=0.020;
ToA_t=ToA+Gaurd_Time; % Total Time on Air.
Duty_Cycle=1;%

% receive the number of ED and then check to be a number
inp = input('Please enter the number of end devices:');  
while (isnumeric(inp) == false)
            disp('It is not a number. Wrong entry')
            inp = input('Please enter the number of end devices:'); 
end
number_of_ed=inp;

% other initial variables
counter=zeros(number_of_ed,2);
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

disp('Implementing the scheduling technique ...')

%% scheduling technique and filling the places - main body
% FAIR policy

% initialise %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for the first one %%%%%%%%%%%%%%%%%%%%%%
overall_mat(1,5)=overall_mat(1,1);
overall_mat(1,6)=overall_mat(1,1)+ToA_t;
counter(overall_mat(1,3),1)=counter(overall_mat(1,3),1)+1;
ind=1; % index of last success

% for the others %%%%%%%%%%%%%%%%%%%%%%%%%
for i=2:size(overall_mat,1)
    
    k1=overall_mat(i,1);
    k2=overall_mat(i,2);

    kp1=overall_mat(ind,5);
    kp2=overall_mat(ind,6);
    
    if k1>kp2
        kex1=k1;
        kex2=k1+ToA_t;
    else
        kex1=kp2+0.001;
        kex2=kex1+ToA_t;
    end
    
    if kex2<=k2
        ind_col=find(overall_mat(:,1)>=kex1 & overall_mat(:,1)<=kex2);
        if isempty(ind_col)==0
            ind2_col=find(counter(overall_mat(ind_col,3),1)==min(counter(overall_mat(ind_col,3),1)) & overall_mat(ind_col,1)==min(overall_mat(ind_col,1)));
        
            if (i==ind_col(ind2_col(1))) 
                overall_mat(i,5)=kex1;
                overall_mat(i,6)=kex2;
                counter(overall_mat(i,3),1)=counter(overall_mat(i,3),1)+1;
                ind=i;
            else
                counter(overall_mat(i,3),2)=counter(overall_mat(i,3),2)+1;
            end
        
        else
                overall_mat(i,5)=kex1;
                overall_mat(i,6)=kex2;
                counter(overall_mat(i,3),1)=counter(overall_mat(i,3),1)+1;
                ind=i;
        end
    else
        counter(overall_mat(i,3),2)=counter(overall_mat(i,3),2)+1;
    end 
end

%% Optimal Scheduling
disp('Trying to improve the chances...')

hope_mat=zeros(number_of_ed,2);
hope_expected=zeros(1,2);
collision_found=0;
helped=0;
couldnot_help=0;

for i=1:number_of_ed
    if (overall_mat(i,5)~=0)
        hope_mat(i,1)=overall_mat(i,2)-overall_mat(i,5);
        if (hope_mat(i,1)>((100/Duty_Cycle)+1)*ToA_t)
            hope_mat(i,2)=1;
            hope_expected(1,:)=[overall_mat(i,5)+100*Duty_Cycle,overall_mat(i,6)+100*Duty_Cycle];
            for j=1:number_of_ed
                if (j~=i)
                    A=hope_expected(1,1);
                    B=hope_expected(1,2);
                    C=overall_mat(j,5);
                    D=overall_mat(j,6);
                    if (A<D & B>C)==1
                        collision_found=1;
                        couldnot_help=couldnot_help+1;
                    end
                end
            end
            if collision_found==0
                k=size(overall_mat,1);
                overall_mat(k+1,5)=A;
                overall_mat(k+1,6)=B;
                overall_mat(k+1,1:3)=overall_mat(i,1:3);
                overall_mat(k+1,4)=overall_mat(k,4)+1;
                counter(i,1)=counter(i,1)+1;
                helped=helped+1;
            end
        end
    end
end
caption=[' >>>>', num2str(helped), ' times helped to have more chances and ', num2str(couldnot_help), ' could not be helped because of probability of having collision'];
disp(caption)

%% counting the runtime with tic in the top and toc here
toc
disp('Drawing the histogram of the output')

histogram(counter(:,1))
 xlim([0 40])
 hold on

%% performance calculations
disp('Calculating the performance - Number of TX per device')

disp('average')
xp1=mean(counter(:,1))
disp('minimum')
xp2=min(counter(:,1))
disp('maximum')
xp3=max(counter(:,1))
disp('Sent - Success')
 sum(counter(:,1))
disp('Couldnot send')
 sum(counter(:,2))
