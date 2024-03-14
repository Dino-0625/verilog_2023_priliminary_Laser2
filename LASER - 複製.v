//stamp
module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output DONE);

parameter GETEDATA = 3'b000;
parameter LOOP = 3'b001;
parameter DECIDE_STEP = 3'b010;

parameter CALCULATE = 3'b011;
parameter CALCULATE2 = 3'b100;
parameter FINISH = 3'b101;

reg [1:0] count;
reg turn, changed, arr; //0 means C1, 1 means C2
reg [2:0] state, nextState;
reg [3:0] TX, TY, NX, NY, TX_t, TY_t; 
reg [5:0] num_count, C1Max, C2Max, AllMax, total_no_shadow, total, step, step_end;
reg array [0:15][0:15];
reg array_ [0:255];         
assign DONE = (state == FINISH);
wire arr_with_mask, inshadow, inshadow1, inshadow2,inshadow3, inshadow4, inshadow5, clear, writeable;
wire TX_B1, TX_B2, TX_B3, TX_B4, TX_S1, TX_S2, TX_S3, TX_S4;
wire [4:0] TX_m_NX, TY_m_NY, TX_NX, TY_NY;


assign TX_B4 = (TX >= 4);// bigger or equal than 4
assign TX_B3 = (TX >= 3);// bigger or equal than 3
assign TX_B2 = (TX >= 2);// bigger or equal than 2
assign TX_B1 = (TX >= 1);// bigger or equal than 1

assign TX_S4 = (TX <= 11);// smaller or equal than 4
assign TX_S3 = (TX <= 12);// smaller or equal than 3
assign TX_S2 = (TX <= 13);// smaller or equal than 2
assign TX_S1 = (TX <= 14);// smaller or equal than 1
assign clear = (state == FINISH);                  
assign writeable = (state == GETEDATA);
wire [3:0] TX_plus_4,TX_plus_3 ,TX_plus_2 ,TX_plus_1 ,TX_minus_1,TX_minus_2,TX_minus_3,TX_minus_4,
TY_plus_4 ,TY_plus_3 ,TY_plus_2 ,TY_plus_1 ,TY_minus_1,TY_minus_2,TY_minus_3,TY_minus_4; 
assign TX_plus_4 = TX + 4;
assign TX_plus_3 = TX + 3;
assign TX_plus_2 = TX + 2;
assign TX_plus_1 = TX + 1;
assign TX_minus_1 = TX - 1;
assign TX_minus_2 = TX - 2;
assign TX_minus_3 = TX - 3;
assign TX_minus_4 = TX - 4;

assign TY_plus_4 = TY + 4;
assign TY_plus_3 = TY + 3;
assign TY_plus_2 = TY + 2;
assign TY_plus_1 = TY + 1;
assign TY_minus_1 = TY - 1;
assign TY_minus_2 = TY - 2;
assign TY_minus_3 = TY - 3;
assign TY_minus_4 = TY - 4;

integer i, j;
/*
always@(posedge CLK)begin
for(i = 0;i <= 15;i = i + 1)begin
			for(j = 0;j <= 15; j = j+ 1)begin
				array_[i*16 + j] <= array[i][j];
				
			end
		end
end*/
assign TX_NX = (TX_t - NX);
assign TY_NY = (TY_t - NY);
assign TX_m_NX = (TX_NX[4] ? (~TX_NX + 1) : (TX_NX));
assign TY_m_NY = (TY_NY[4] ? (~TY_NY + 1) : (TY_NY));

assign inshadow1 = ((TX_m_NX) == 4) & (TY_m_NY == 0);
assign inshadow2 = ((TX_m_NX) == 3) & (TY_m_NY <= 2);
assign inshadow3 = ((TX_m_NX) == 2) & (TY_m_NY <= 3);
assign inshadow4 = ((TX_m_NX) == 1) & (TY_m_NY <= 3);
assign inshadow5 = (TX_m_NX == 0)   & ((TY_m_NY) <= 4);
assign inshadow = !(inshadow1 || inshadow2 || inshadow3 || inshadow4 || inshadow5);
assign arr_with_mask = (arr & inshadow);

always@(state, num_count, TX, TY, step)begin

		case(state)
			GETEDATA:begin
				if(num_count == 40 - 1)
					nextState = LOOP;
				else
					nextState = GETEDATA;
			end
			DECIDE_STEP:
				nextState = CALCULATE;
		
			CALCULATE:begin
				if(step == step_end)
					nextState = LOOP;
				else
					nextState = CALCULATE;
			end
			
			
			LOOP:begin
				if((TX == 15) && (TY == 15) && (changed == 0))
					nextState = FINISH;
				else
					nextState = DECIDE_STEP;
			end
			
			FINISH:
				nextState = GETEDATA;
			default:
				nextState = 0;
		endcase
end

always@(posedge CLK or posedge RST)begin
	if(RST)
		state <= 0;
	else
		state <= nextState;
end

always@(posedge CLK)begin
	if((RST) || (clear == 1))begin
		for(i = 0;i <= 15;i = i + 1)begin
			for(j = 0;j <= 15; j = j+ 1)begin
				array[i][j] <= 0;
				
			end
		end
		
	end
	else if(writeable == 1)begin
		for(i = 0;i <= 15;i = i + 1)begin
			for(j = 0;j <= 15; j = j+ 1)begin
				array[i][j] <= array[i][j];
			end
		end
		array[Y][X] <= 1;
	end
	
	else begin
		for(i = 0;i <= 15;i = i + 1)begin
			for(j = 0;j <= 15; j = j+ 1)begin
				array[i][j] <= array[i][j];
			end
		end
		
	end
end

always@(posedge CLK)begin

	step <= step + 1;
	if(clear)begin
		NX <= NX;
		NY <= NY;
	end
	if(RST)begin
		NX <= 0;
		NY <= 0;
		
	end
	if(RST || clear)begin
		num_count <= 0;
		total_no_shadow <= 0;
		total <= 0;
		turn <= 0;


		step <= 6'b000000;
		step_end <= 6'b000000;
		
		
		changed <= 0;
		TX <= 0;
		TY <= 0;
	
		C1X <= 0;
		C1Y <= 0;
		C2X <= 0;
		C2Y <= 0;
		AllMax <= 0;
		C2Max <= 0;
		C1Max <= 0;
		
		intersection <= 0;
	end
	else
		case(state)
			GETEDATA:begin
				intersection <= 0;
				num_count <= num_count + 1;
				total_no_shadow <= 0;
				total <= 0;
			end
			LOOP:begin
				if(((total + C2Max) > AllMax) && (turn == 0))begin
					
					changed <= 1;
					C1Max <= total_no_shadow;
					C1X <= TX;
					C1Y <= TY;
					AllMax <= (total + C2Max);
				end
				else if(((total + C1Max) >= AllMax) && (turn == 1))begin
					if(((total + C1Max) == AllMax)  && (C2Max < total_no_shadow))begin
						changed <= 1;
						C2Max <= total_no_shadow;
						C2X <= TX;
						C2Y <= TY;
					end
					else if((total + C1Max) == AllMax)begin
						changed <= changed;
						C2Max <= C2Max;
						C2X <= C2X;
						C2Y <= C2Y;
					end
					else begin
						changed <= 1;
						C2Max <= total_no_shadow;
						C2X <= TX;
						C2Y <= TY;
					end
					AllMax <= (total + C1Max);
				end
				else
					changed <= changed;
					
				if((TX == 15) && (TY == 15))begin
					changed <= 0;
					TX <= 0;
					TY <= 0;
					turn <= ~turn;
					NX <= turn ? C2X : C1X;
					NY <= turn ? C2Y : C1Y;
				end
				else if(TX == 15)begin
					turn <= turn;
					TX <= 0;
					TY <= TY_plus_1;
				end
				else 
					TX <= TX_plus_1;

				total_no_shadow <= 0;
				total <= 0;
				
			end
			DECIDE_STEP:begin
				case(TY)
					3: begin
						case(TX)
							1:step <= 2;
							0:step <= 3;
							default:step <= 1;
						endcase
					end
					2: begin
						case(TX)
							2:step <= 7;
							1:step <= 8;
							0:step <= 9;
							default: step <= 6;
						endcase
					end
					1: begin
						case(TX)
							2:step <= 14;
							1:step <= 15;
							0:step <= 16;
							default:step <= 13;
						endcase
					end
					0: begin
						case(TX)
							3:step <= 21;
							2: step <= 22;
							1: step <= 23;
							0: step <= 24;
							default: step <= 20;
						endcase
					end
					default:
						step <= 0;
				endcase
				case(TY)
					15: step_end <= 28;
					14: step_end <= 35;
					13: step_end <= 42;
					12: step_end <= 47;
					default:
						step_end <= 48;
				endcase
				
				total_no_shadow <= 0;
				total <= 0;
		
			end
			
			CALCULATE:begin
				
				if(arr == 1)
					total_no_shadow <= total_no_shadow + 1;
				else
					total_no_shadow <= total_no_shadow;
				if(arr_with_mask == 1) 
					total <= 1 + total;
				else
					total <= total;
			end
			
			FINISH:begin
				
				total_no_shadow <= 0;
				total <= 0;
			end
			default:begin

				total_no_shadow <= 0;
				total <= 0;
				
				num_count <= 0;
			end
		endcase
end

always@(step)begin

		case(step)
			0:begin
				TY_t = TY_minus_4;
				TX_t = TX;
				arr = array[TY_minus_4][TX];
			
			end
			1:begin
				TY_t = TY_minus_3;
				
				if(TX_B2)begin
					arr = array[TY_minus_3][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
				
			end
			2:begin
				TY_t = TY_minus_3;
				
				if(TX_B1)begin
					arr = array[TY_minus_3][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			3:begin
				TY_t = TY_minus_3;
				TX_t = TX;
				arr = array[TY_minus_3][TX];
				
			end
			4:begin
				TY_t = TY_minus_3;
			
				if(TX_S1)begin
					arr = array[TY_minus_3][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			5:begin
				TY_t = TY_minus_3;
				
				if(TX_S2)begin
					TX_t = TX_plus_2;
					arr = array[TY_minus_3][TX_plus_2];
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end	
			6:begin
				TY_t = TY_minus_2;
				
				if(TX_B3) begin
					arr = array[TY_minus_2][TX_minus_3];
					TX_t = TX_minus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			7:begin
				TY_t = TY_minus_2;
				
				if(TX_B2)begin
					arr = array[TY_minus_2][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			8:begin
				TY_t = TY_minus_2;
				
				if(TX_B1)begin
					arr = array[TY_minus_2][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			9:begin
				TY_t = TY_minus_2;
				TX_t = TX;
				arr = array[TY_minus_2][TX];
				
			end
			10:begin
				TY_t = TY_minus_2;
				
				if(TX_S1)begin
					arr = array[TY_minus_2][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			11:begin
				TY_t = TY_minus_2;
				
				if(TX_S2)begin
					arr = array[TY_minus_2][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			12:begin
				TY_t = TY_minus_2;
				
				if(TX_S3)begin
					arr = array[TY_minus_2][TX_plus_3];
					TX_t = TX_plus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			13:begin
				TY_t = TY_minus_1;
				
				if(TX_B3)begin
					arr = array[TY_minus_1][TX_minus_3];
					TX_t = TX_minus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			14:begin
				TY_t = TY_minus_1;
				
				if(TX_B2)begin
					arr = array[TY_minus_1][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			15:begin
				TY_t = TY_minus_1;

				if(TX_B1)begin
					arr = array[TY_minus_1][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			16:begin 
				TY_t = TY_minus_1;
				TX_t = TX;
				arr = array[TY_minus_1][TX];
				
			end
			17:begin
				TY_t = TY_minus_1;
				
				if(TX_S1)begin
					arr = array[TY_minus_1][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			18:begin
				TY_t = TY_minus_1;
				if(TX_S2)begin
					arr = array[TY_minus_1][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			19:begin
				TY_t = TY_minus_1;
				
				if(TX_S3)begin
					arr = array[TY_minus_1][TX_plus_3];
					TX_t = TX_plus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			20:begin 
				TY_t = TY;
				
				if(TX_B4)begin
					arr = array[TY][TX_minus_4];
					TX_t = TX_minus_4;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			21:begin 
				TY_t = TY;
				
				if(TX_B3)begin
					arr = array[TY][TX_minus_3];
					TX_t = TX_minus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			22:begin 
				TY_t = TY;
				
				if(TX_B2)begin
					arr = array[TY][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			23:begin 
				TY_t = TY;
				
				if(TX_B1)begin
					arr = array[TY][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			24:begin 
				TY_t = TY;
				TX_t = TX;
				arr = array[TY][TX]; 
			
			end
			25:begin 
				TY_t = TY;
				if(TX_S1)begin
					arr = array[TY][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			26:begin 
				TY_t = TY;
				
				if(TX_S2)begin
					arr = array[TY][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			27:begin 
				TY_t = TY;
				
				if(TX_S3)begin
					arr = array[TY][TX_plus_3];
					TX_t = TX_plus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			28:begin 
				TY_t = TY;
				
				if(TX_S4)begin
					arr = array[TY][TX_plus_4];
					TX_t = TX_plus_4;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			29:begin 
				TY_t = TY_plus_1;
				
				if(TX_B3)begin
					arr = array[TY_plus_1][TX_minus_3];
					TX_t = TX_minus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			30:begin
				TY_t = TY_plus_1;
				
				if(TX_B2)begin
					arr = array[TY_plus_1][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			31:begin 
				TY_t = TY_plus_1;
				
				if(TX_B1)begin
					arr = array[TY_plus_1][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			32:begin 
				TY_t = TY_plus_1;
				TX_t = TX;
				arr =	array[TY_plus_1][TX]            ;
								
			end
			33:begin 
				TY_t = TY_plus_1;
				
				if(TX_S1)begin
					arr = array[TY_plus_1][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			34:begin 
				TY_t = TY_plus_1;
				
				if(TX_S2)begin
					arr = array[TY_plus_1][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			35:begin 
				TY_t = TY_plus_1;
				
				if(TX_S3)begin
					arr = array[TY_plus_1][TX_plus_3];
					TX_t = TX_plus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			36:begin 
				TY_t = TY_plus_2;
				
				if(TX_B3)begin
					arr = array[TY_plus_2][TX_minus_3];
					TX_t = TX_minus_3;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			37:begin 
				TY_t = TY_plus_2;
				
				if(TX_B2)begin
					arr = array[TY_plus_2][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			38:begin 
				TY_t = TY_plus_2;
				
				if(TX_B1)begin
					arr = array[TY_plus_2][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			39:begin 
				TY_t = TY_plus_2;
				TX_t = TX;
				arr = array[TY_plus_2][TX]; 
			
			end
			40:begin 
				TY_t = TY_plus_2;
				
				if(TX_S1)begin
					arr = array[TY_plus_2][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			41:begin 
				TY_t = TY_plus_2;
				
				if(TX_S2)begin
					arr = array[TY_plus_2][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			42:begin 
				TY_t = TY_plus_2;
				
				if(TX_S3)begin
					arr = array[TY_plus_2][TX_plus_3];
					TX_t = TX_plus_3;
				end
				else begin
					TX_t = 0;
					arr = 0;
				end
			end
			43:begin 
				TY_t = TY_plus_3;
				
				if(TX_B2)begin
					arr = array[TY_plus_3][TX_minus_2];
					TX_t = TX_minus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			44:begin 
				TY_t = TY_plus_3;
				
				if(TX_B1)begin
					arr = array[TY_plus_3][TX_minus_1];
					TX_t = TX_minus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			45:begin 
				TY_t = TY_plus_3;
				TX_t = TX;
				arr = array[TY_plus_3][TX]            ;
			
			end
			46:begin 
				TY_t = TY_plus_3;
				
				if(TX_S1)begin
					arr = array[TY_plus_3][TX_plus_1];
					TX_t = TX_plus_1;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			47:begin 
				TY_t = TY_plus_3;
				
				if(TX_S2)begin
					arr = array[TY_plus_3][TX_plus_2];
					TX_t = TX_plus_2;
				end
				else begin
					arr = 0;
					TX_t = 0;
				end
			end
			48:begin 
				TY_t = TY_plus_4;
				TX_t = TX;
				arr = array[TY_plus_4][TX];
				
			end
			default:begin
				arr = 0;
				TX_t = 0;
				TY_t = 0;
			end
		endcase
end

endmodule


