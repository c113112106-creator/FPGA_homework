
`timescale 1ns / 1ps

module pinpom_weeee(
    input clk,
    input rst,
    input hit_r,
    input hit_l,
    output [7:0] led_ball,
	output hsync,vsync,
	output [3:0] vga_r,vga_g,vga_b
);
    wire ball_tick,vga_clk,hit_l_b,hit_r_b;
	wire [3:0] win_r,win_l;
	wire [1:0] game_state_w;
	
	button U001(.click(hit_l_b),.btn(hit_l),.clk(clk),.rst(rst));
	button U010(.click(hit_r_b),.btn(hit_r),.clk(clk),.rst(rst));
    division u0 (
        .clk(clk),
        .rst(rst),
        .ball_tick(ball_tick)
    );
	division2 U2(
		.rst(rst),
		.vga_clk(vga_clk),
		.clk(clk)
	);
    location_controler u1 (
        .clk(clk),
        .ball_tick(ball_tick),
        .rst(rst),
        .hit_r(hit_r_b),
        .hit_l(hit_l_b),
		.win_r(win_r),
		.win_l(win_l),
		.game_state(game_state_w),
        .led_ball(led_ball)
    );
	vga U8(
		.state_ref(win_r),
		.state_fast(win_l),
		.clk(vga_clk),
		.game_state(game_state_w),
		.rst(rst),
		.hsync(hsync),
		.vsync(vsync),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b)
	);
endmodule



module division2(
	input clk,rst,
	output vga_clk
	);
	reg [27:0]cnt;
	assign vga_clk=cnt[1];///////////////////
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			cnt<=28'd0;
		end
		else begin
			cnt <= cnt+28'd1;
		end
	end
endmodule



module location_controler(
    input clk,
    input ball_tick,
    input rst,
    input hit_r,
    input hit_l,
    output reg [1:0] game_state,
    output reg [7:0] led_ball,
    output reg [3:0] win_r,win_l
);

    localparam [25:0] TIMEOUT_COUNT = 26'd49999999;

    localparam PLAY = 2'd0;
    localparam WAIT = 2'd1;

    reg win;
    reg direction;
    reg [25:0] good_hit_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            direction <= 1'b0;
            led_ball <= 8'b00100000;
            win <= 1'b0;
            good_hit_counter <= 26'd0;
            game_state <= PLAY;
            win_r <= 4'd0;
            win_l <= 4'd0;
        end
        else begin
            case (game_state)
                PLAY: begin
                    if (direction == 1'b0) begin
                        if (led_ball == 8'b00000001) begin
                            if (hit_r) begin
                                direction <= 1'b1;
                                good_hit_counter <= 26'd0;
                            end
                            else if (good_hit_counter >= TIMEOUT_COUNT - 1'b1) begin
                                win <= 1'b0;
                                win_l <= win_l + 4'd1;
                                game_state <= WAIT;
                                led_ball <= 8'b10000000;
                                direction <= 1'b1;
                                good_hit_counter <= 26'd0;
                            end
                            else begin
                                good_hit_counter <= good_hit_counter + 1'b1;
                            end
                        end
                        else begin
							if (hit_r) begin
                                win <= 1'b0;
                                win_l <= win_l + 4'd1;
                                game_state <= WAIT;
                                led_ball <= 8'b10000000;
                                direction <= 1'b1;
                                good_hit_counter <= 26'd0;
                            end
                            good_hit_counter <= 26'd0;
                            if (ball_tick)
                                led_ball <= led_ball >> 1;
                        end
                    end
                    else begin
                        if (led_ball == 8'b10000000) begin
                            if (hit_l) begin
                                direction <= 1'b0;
                                good_hit_counter <= 26'd0;
                            end
                            else if (good_hit_counter >= TIMEOUT_COUNT - 1'b1) begin
                                win <= 1'b1;
                                win_r <= win_r + 4'd1;
                                game_state <= WAIT;
                                led_ball <= 8'b00000001;
                                direction <= 1'b0;
                                good_hit_counter <= 26'd0;
                            end
                            else begin
                                good_hit_counter <= good_hit_counter + 1'b1;
                            end
                        end
                        else begin
							if (hit_l) begin
                                win <= 1'b1;
                                win_r <= win_r + 4'd1;
                                game_state <= WAIT;
                                led_ball <= 8'b00000001;
                                direction <= 1'b0;
                                good_hit_counter <= 26'd0;
                            end
                            good_hit_counter <= 26'd0;
                            if (ball_tick)
                                led_ball <= led_ball << 1;
                        end
                    end
                end
                WAIT: begin
                    good_hit_counter <= 26'd0;
                    if ((win == 1'b0) && hit_l) begin

                        game_state <= PLAY;
                        led_ball <= 8'b10000000;
                        direction <= 1'b1;
                    end
                    else if ((win == 1'b1) && hit_r) begin
                        game_state <= PLAY;
                        led_ball <= 8'b00000001;
                        direction <= 1'b0;
                    end
                end
                default: begin
                    game_state <= PLAY;
                    led_ball <= 8'b00100000;
                    direction <= 1'b0;
                    good_hit_counter <= 26'd0;
                end
            endcase
        end
    end

endmodule





module division(
    input clk,
    input rst,
    output reg ball_tick
);

    reg [25:0] cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 26'd0;
            ball_tick <= 1'b0;
        end
        else begin
            ball_tick <= 1'b0;

            if (cnt == 26'd49999999) begin
                cnt <= 26'd0;
                ball_tick <= 1'b1;
            end
            else begin
                cnt <= cnt + 26'd1;
            end
        end
    end

endmodule

module vga(
	input clk,rst,
	input [1:0] game_state,
	input [3:0] state_fast,
	input [3:0] state_ref,
	output hsync,vsync,
	output reg [3:0] vga_r,vga_g,vga_b
	);
	parameter   H_SYNC=96,
				H_SYNC_BACK_Porch=48,
				H_SYNC_ADDERSSABLE_VIDEO=630,
				H_SYNC_FRONT_PORCH=26,
				H_SYNC_PERIOD=H_SYNC+H_SYNC_ADDERSSABLE_VIDEO+H_SYNC_BACK_Porch+H_SYNC_FRONT_PORCH;
				
	parameter   V_SYNC=2,
				V_SYNC_BACK_Porch=33,
				V_SYNC_ADDERSSABLE_VIDEO_1=240,
				V_SYNC_ADDERSSABLE_VIDEO=480,
				V_SYNC_FRONT_PORCH=10,
				V_SYNC_PERIOD=V_SYNC+V_SYNC_ADDERSSABLE_VIDEO+V_SYNC_BACK_Porch+V_SYNC_FRONT_PORCH;
	reg [9:0] h_counter,v_counter;
	reg [2:0] go_mode;

	wire valid_flag;
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			h_counter<=10'd0;
		end
		else begin
			if((h_counter==H_SYNC_PERIOD-1))begin
				h_counter<=10'd0;
			end
			else begin
				h_counter<=h_counter+10'd1;
			end
		end
	end
	
	always@(*)begin
		if(rst)begin
			go_mode=3'd0;
		end
		else begin
			if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+0 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+104)begin
				go_mode=3'd0;
			end
			else if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+104 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+209)begin
				go_mode=3'd1;
			end
			else if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+209 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+314)begin
				go_mode=3'd2;
			end
			else if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+314 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+419)begin
				go_mode=3'd3;
			end
			else if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+419 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+524)begin
				go_mode=3'd4;
			end
			else if(h_counter>=(H_SYNC+H_SYNC_BACK_Porch)+524 && h_counter<(H_SYNC+H_SYNC_BACK_Porch)+629)begin
				go_mode=3'd5;
			end
			else begin
				go_mode=3'd6;
			end
		end
	end
	
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			v_counter<=10'd0;
		end
		else begin
			if((v_counter==V_SYNC_PERIOD-1)&&(h_counter==H_SYNC_PERIOD-1))begin
				v_counter<=10'd0;
			end
			else begin
				if(h_counter==H_SYNC_PERIOD-1)begin
					v_counter<=v_counter+10'd1;
				end
				else begin
				v_counter<=v_counter;
				end
			end
		end
	end
	
	always @(posedge clk or posedge rst) begin
        if (rst) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
        else begin
            if (!valid_flag) begin

                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
            // =================================================
            // 上半部：state_fast
            // =================================================
            else if (v_counter < V_SYNC + V_SYNC_BACK_Porch + 240) begin
                if (state_fast >= go_mode) begin
                    // 黃色
                    vga_r <= 4'hf;
                    vga_g <= 4'hf;
                    vga_b <= 4'h0;
                end
                else begin
					if(game_state==1)begin
						vga_r <= 4'hf;
						vga_g <= 4'h0;
						vga_b <= 4'hf;
					end
					else begin
						vga_r <= 4'h0;
						vga_g <= 4'h0;
						vga_b <= 4'h0;
					end
                end
            end
            // =================================================
            // 下半部：state_ref
            // =================================================
            else begin
                if (state_ref >= go_mode) begin
                    // 藍色
                    vga_r <= 4'h0;
                    vga_g <= 4'h0;
                    vga_b <= 4'hf;
                end
                else begin
                    if(game_state==1)begin
						vga_r <= 4'hf;
						vga_g <= 4'h0;
						vga_b <= 4'hf;
					end
					else begin
						vga_r <= 4'h0;
						vga_g <= 4'h0;
						vga_b <= 4'h0;
					end
                end
            end
        end
    end
	assign hsync=(h_counter<=H_SYNC-1'b1)?1'b1:1'b0;
	assign vsync=(v_counter<=V_SYNC-1'b1)?1'b1:1'b0;
	assign valid_flag=(h_counter>=(H_SYNC+H_SYNC_BACK_Porch))&&(h_counter<=(H_SYNC+H_SYNC_BACK_Porch+H_SYNC_ADDERSSABLE_VIDEO))&&
	(v_counter>=(V_SYNC+V_SYNC_BACK_Porch))&&(v_counter<=(V_SYNC+V_SYNC_BACK_Porch+V_SYNC_ADDERSSABLE_VIDEO));
endmodule

module button(
	input clk,rst,btn,
	output click
	);
	reg [23:0]decnt;
	reg sig_dly,sig;
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			sig<=0;
			decnt<=0;
		end
		else begin
			if(btn==1'b1)begin
				if(decnt<24'd499999)begin
					decnt<=decnt+24'd1;
					sig<=1'b0;
				end
				else begin
					decnt<=decnt;
					sig<=1'b1;
				end
				end
			else begin
				decnt<=24'd0;
				sig<=1'b0;
			end
		end
	end
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			sig_dly<=1'b0;
		end
		else begin
			sig_dly<=sig;
		end
	end
	assign click=sig;
endmodule