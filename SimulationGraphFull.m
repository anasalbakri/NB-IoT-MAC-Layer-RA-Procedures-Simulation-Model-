%Simulation: 


%Total Generation rate that is used only for graph
%It covers the range from 0 to 10 packets/second  
LAMBDA=0:(12.5/60):10;

%Initialization of generation rate variable Lambda: 
Lambda=0;

%Initialization of array of mean service time which correspond to the 49 points of
%the graph  
MeanServiceTime=ones(1,49);

%Initialization of array of mean delay which correspond to the 49 points of the graph:
MeanDelay=ones(1,49);


%Initialization of Rho (Probability that a queue is busy) for every queue and 
%for the 49 points of the graphs: 
Rho=zeros(5,49);


%The loop is for every point of the graph 
for z=1:48

%Increment of generation rate for every new point:
Lambda=Lambda+(12.5/60);     

%Initialization of array of mean service time which correspond to the 20 trials
%for every point in the graph:
MeanS=ones(1,20);           

%Initialization of array of mean service time which correspond to the 20 trials
%for every point in the graph:
MeanD=ones(1,20);   


%Initialization of RHO (Probability that a queue is busy) for the 20 trials 
%of every point in the graph:
RHO=ones(5,20);

%The loop of the 20 trials for every point of the graph        
for h=1:20

    
%Initialization of parameters for every packet: 


%Transmission time:
Tx=0.012;                                

%Backoff=[7 13 51 103 206];
%Defining Maximum Backoff slots array (w in Analysis)
Backoff=[7 13 26 51 103];


%Initialization of BusyCount 
%BusyCount is an array for every queue represents the number of slots where the queue was busy
BusyCount=ones(5,1);

%Initialization of DiscardId: This array will contain the ids of all packets that were discarded
DiscardId=[];

%Initialization of Discard: This variable will be the number of packets discardrd
Discard=0;

%Initialization of arrival times array for the 4100 packets 
Ta=ones(1,4100);

%Initialization of Id: array for the 4100 packets 
%Id of the packet is its order of generation
Id=ones(1,4100);

%Queue ID: the Queue chosen by this packet among the 5 available queues 
%Initialization of Queues array for the 4100 packets:
QuID=ones(1,4100);


%Id of first packet (because loop later will start from 2) 
Id(1)=1;

%Generating first queue ID: 
% randi(5,1) will select a random value in the range [1 5] accoring to
% discrete uniform distribution. 
QuID(1)=randi(5,1);

%Defining arrival time of first packet: 
% random("Exponential",1/Lambda) will generate an exponentially distributed
% random variable with mean=1/Lambda 
Ta(1)=random("Exponential",1/Lambda);

% This for loop will generate arrival time and queue ID for all packets 
for i=1:4100
%New arrival time = last arrival time + Expinentially ditributed time
%interval 
Ta(i+1)=Ta(i)+random("Exponential",1/Lambda); 

%Packet ID (order of generation)   
Id(i+1)=i+1;

%Queue ID 
QuID(i+1)=randi(5,1);

end


%Defining packet array (pak): 
%Array of 5 rows and 4100 columns corresponding to the 4100 packets 
%First row: Packet Id 
%Second row: Arrival time 
%Third row: Queue ID of the packet
%Forth row: starting service time (time of reaching to the head-of-line of
%its queue) 
%Fifth row: Departure time
pak=[Id;Ta;QuID;zeros(size(Id));zeros(size(Id))];

%Initialization of Users array: 
%It's an array of 5 rows corresponding to 5 users and 3 columns 
%First column: Number of packets in the queue at the moment 
%Second column: Number of retransmission of the head-of-line packet 
%Third column: Number of remaining backoff slots till the head-of-line packet
%can transmit again
U=[zeros(1,3);zeros(1,3);zeros(1,3);zeros(1,3);zeros(1,3)];

%Initialization of User's packets Ids cell
%This is a cell of 5 columns correspong to the 5 users that contains the Ids
%of all packets available at the moment in the user queue 
%Cell is used instead of array because number of rows might be different for each column(user) 
UpakId=cell(5,1);


%Initialization of time (t):
    t=0;

%Starting the main loop:
%=============================================================================================
%=============================================================================================
%This loop performs all basic operations at the start of every new slot
%Every iteration of this loop correspond to a new slot (Thus increment of
%time in the loop is the actual slot time)
%while is used to ensure that all packets were served: it stops when all
%packet departure times are nonzeroes (Thus all packets served)

    while ~all(pak(5,:))

    t=t+0.04;           %Increment of time in every iteration (slot time) 48
    
    %Upak is an array of 3 columsn for new arrivals which were generated in the period between the current slot and previous slot 
    Upak=pak(:,Ta>(t-0.04)&Ta<=t,:);

   %Adding the new generations to the users queues'  
   %==========================================================================================
   % in this step we will update the users arrays' with the new generations stored in Upak 
   % 
   if(isempty(Upak))
    %If empty do nothing 
    else
    for i=1:size(Upak,2)
        if U(Upak(3,i),1)==0        %If user has no packets in its queue, the new packet will be immediately the head-of-line packet 
            pak(4,Upak(1,i))=pak(2,Upak(1,i));  %Starting service time of this packet is same as its arrival time
        end
        
        U(Upak(3,i),1)=U(Upak(3,i),1)+1;        %Increasing number of packets by one
        UpakId{Upak(3,i),1}=[UpakId{Upak(3,i),1} Upak(1,i)];    %Adding the new packet id to the user's cell
    end
   end
   %===========================================================================================

   
   
   %Rho (Probability that a queue is busy)
   %===========================================================================================
   %For loop for every queue to check whether it's busy or not
   %BusyCount is a variable of the number of slots where the queue was busy 
    
   for i=1:5
     if U(i,1)>0
     BusyCount(i)=BusyCount(i)+1;   
     end
   end
   
   
   
   
   
   % Checking for who want to send 
   %===========================================================================================
   L=[];  %L is array that will contain ids of users who want to send 
    c=0;  %c is number of users willing to send in this slot
          % if c=1 ==> successful transmission 
          % if c>1 ==> collision 
          
    for k=1:5
        if U(k,3)~=0                    %Check if user is in backoff
            U(k,3)=U(k,3)-1;        %if he's in backoff reduce remaining slots by one 
            if U(k,3)==0&&U(k,1)~=0 %if remaining slots=0 he will attempt sending
                c=c+1;              %increase c by one 
                L=[L k];            %add the id of this user to L
            end   
        else                            %For users not in backoff
            if U(k,1)~=0                %Check if user has packets to send
                c=c+1;
                L=[L k];
            end
            
        end
    end
   %==========================================================================================


    
   %Case of successful transmission
   %==========================================================================================
 
    if c==1                             
      U(L,1)=U(L,1)-1;                  % Reducing number of current packets of the user by one
      U(L,2)=0;                         % Resetting retransmission to 0
      U(L,3)=0;                         % Resetting Backoff remaining slots to 0
      pak(5,UpakId{L,1}(1))=t+Tx;       % Updating departure time of the successful packet
           %It is equal to the current slot time (t) plus transmission time (Tx)
           %The Id of this packet is stored in UpakId. 
           %This is actually the main reason of having the cell UpakId

      UpakId{L,1}=UpakId{L,1}(2:end);   % Removing the departing packet id from UpakId
      if isempty(UpakId{L,1})
            %if the departing packet was the only packet in queue => Do nothing
      else  %if there were packets behind it => update their starting service time
      pak(4,UpakId{L,1}(1))=t+0.04;          %Starting servie time of new packet 
      end
      
      
    %Case of collision
    %==========================================================================================
      elseif c>1                          
          
        for m=1:c       %Loop for every user who attempted  
           U(L(m),2)=U(L(m),2)+1;       % Increasng attempt (retransmission) by 1
        %Case of discarding: 
        %======================================================================================
           if U(L(m),2)>5               %If retranmission exceed 5 which is max retransmission attempt (Q in analysis)
               Discard=Discard+1;       %Increase number of discardrd packets
               DiscardId=[DiscardId UpakId{L(m),1}(1)];  %Add the id of the discardrd packet
               pak(5,UpakId{L(m),1}(1))=t+Tx;            % set the departure time of the discarded packet to be t+Tx
               UpakId{L(m),1}=UpakId{L(m),1}(2:end);     % Removing the discarded packet id from UpakId
               
               if isempty(UpakId{L(m),1})
                    %if the discarded packet was the only packet in queue => Do nothing
               else %if there were packets behind it => update their starting service time
                  pak(4,UpakId{L(m),1}(1))=t+0.04;
               end
               U(L(m),1)=U(L(m),1)-1;    % Reducing number of current packets of the user by one
               U(L(m),2)=0;              % Resetting retransmission to 0
               U(L(m),3)=0;              % Resetting Backoff to 0      
        %=====================================================================================

        %General collision case (No discarding):
        %Just let the user choose a backoff vlaue randomly according to
        %uniform distribution between 0 and Backoff corresponding to its
        %current number of retransmission
           else
               U(L(m),3)=randi([0 Backoff(U(L(m),2))],1,1);
               %U(L(m),3)=randi(Backoff(U(L(m),2)));
           end
        %=====================================================================================
        end
    end
    end

%==============================================================================================
%==============================================================================================
%Ending main loop 


%Updating results: 
ServiceTime=pak(5,:)-pak(4,:);   %Service time array
    %It is equal to departure time minus starting service time(time of reaching HOL)
DelaySimulation=pak(5,:)-pak(2,:);        %Delay array 
    %It is equal to departure time minus arrival time

%Finding mean service time for the 4000 packets ignoring the first 100 packets 
MeanS(h)=mean(ServiceTime(101:end));

%Finding mean delay for the 4000 packets ignoring the first 100 packets 
MeanD(h)=mean(DelaySimulation(101:end));  


%Finding total number of slots in the entire time of serving 4100 packets: 
NumSlots=t/0.04;


%Finding Rho(probability that a queu is busy) for every queue: 
for i=1:5
RHO(i,h)=BusyCount(i)/NumSlots;
end

end

%Taking the mean of the 20 trials done for this point 
%This is the array that will be used in the graph
%The more the trials the more accurate the graph will be 
MeanServiceTime(z+1)=mean(MeanS);
MeanDelay(z+1)=mean(MeanD);


%Rho: 
%Taking average of the 20 trials for Rho for every queue:
for i=1:5
    Rho(i,z+1)=mean(RHO(i,:));
end

end

%Finding total utilization by summing up Rhos of every queue:
Rhototal=ones(1,49); %initialization
for i=1:49
Rhototal(i)=sum(Rho(:,i));
end

%Graph:
%============================================================================================== 
%First value of mean service time correspond to 0 generation rate 
%Since we don't want mean service time to start from 0, we made its value the same
%as the second value  
MeanServiceTime(1)=MeanServiceTime(2);  
MeanDelay(1)=MeanDelay(2);

figure
plot(LAMBDA,MeanDelay)
xlabel('Generation rate in packets/second (Simulation)')
ylabel('Average customer delay in seconds (Simulation)')
figure
plot(LAMBDA.*MeanServiceTime,MeanDelay)
xlabel('Utilization factor (overal load) (Simulation)')
ylabel('Average customer delay in seconds (Simulation)')


%Figure of Lambda vs Rho (probability that a queue is busy): 
figure
plot(LAMBDA,Rhototal)
xlabel('Generation rate in packets/second (Simulation)')
ylabel('Total Utilization \rho=\rho1+\rho2+..+\rhoN (probability that a queue is busy)')
