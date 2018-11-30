library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.game_components.all;
use work.tank_functions.all;

entity game_logic is
	generic(
		tank_width, tank_height, tank_width_buffer : integer
	);
	port(
		clk, rst, global_write_enable : in std_logic;
		
		--Player A inputs
		player_A_speed : in integer;
		player_A_fire : in std_logic;
		
		--Player B inputs
		player_B_speed : in integer;
		player_B_fire : in std_logic;
		
		--Tank attribute inputs
		tank_A_pos_in, tank_B_pos_in : in position;
		tank_A_speed_in, tank_B_speed_in : in integer;
		
		--Tank attribute outputs
		tank_A_pos_out, tank_B_pos_out : out position;
		tank_A_speed_out, tank_B_speed_out : out integer;
		
		--Bullet attribute inputs
		bullet_A_pos_in, bullet_B_pos_in : in position;
		bullet_A_fired_in, bullet_B_fired_in : in std_logic;
		
		--Bullet attribute outputs
		bullet_A_pos_out, bullet_B_pos_out : out position;
		bullet_A_fired_out, bullet_B_fired_out : out std_logic;
		
		--Score keeping
		score_A_out, score_B_out : out integer

	);
end entity game_logic;



architecture behavioral of game_logic is
--types
	
--constants
	constant bullet_speed : integer := 15;
	signal speed_A_updated, speed_B_updated : std_logic;
	signal collision_count_A, collision_count_B : integer := 0;
	signal tank_A_pos, tank_B_pos : position;
	signal tank_A_speed, tank_B_speed : integer := 10;
	signal tank_A_dir, tank_B_dir : std_logic := '0';
		--left: 0
		--right: 1
	signal bullet_A_fired, bullet_B_fired : std_logic;
	signal bullet_A_pos, bullet_B_pos : position;
	signal score_A_out, score_B_out : integer;
	
	begin

	speed_update : process(clk, rst) is
	begin
		if (rising_edge(clk) and global_write_enable = '0') then
			--check only every other cycles
			if (player_A_speed = '1' and speed_A_updated = '0') then
				if (tank_A_speed = 30) then
					tank_A_speed <= 10;
					speed_A_updated <= '1';
				else 
					tank_A_speed <= tank_A_speed + 10;
					speed_A_updated <= '1';
				end if;
			elsif (player_A_speed = '0' and speed_A_updated = '1') then
				--could place a counter here to delay flag unset even more
				speed_A_updated <= '0';
			end if;
			
			if (player_B_speed = '1' and speed_B_updated = '0') then
				if (tank_B_speed = 30) then
					tank_B_speed <= 10;
					speed_B_updated <= '1';
				else 
					tank_B_speed <= tank_B_speed + 10;
					speed_B_updated <= '1';
				end if;
			elsif (player_B_speed = '0' and speed_B_updated = '1') then
				--could place a counter here to delay flag unset even more
				speed_B_updated <= '0';
			end if;

		end if;
	end process;
	tank_update : process(clk, rst) is
		variable tank_A_pos_temp : integer;
	begin 
		if (rising_edge(clk)) then
			if (global_write_enable = '0') then --read state
				--tank A
				tank_A_pos_temp := tank_A_pos_in(0);
				if (tank_A_dir = '1') then --update position based on direction
					-- go further right
					tank_A_pos(0) <= tank_A_pos_temp + tank_A_speed;
				else
					-- go further left
					tank_A_pos(0) <= tank_A_pos_temp - tank_A_speed;
				end if;
				
				--tank B
				tank_B_pos_temp := tank_B_pos_in(0);
				if (tank_B_dir = '1') then --update position based on direction
					-- go further right
					tank_B_pos(0) <= tank_B_pos_temp + tank_B_speed;
				else
					-- go further left
					tank_B_pos(0) <= tank_B_pos_temp - tank_B_speed;
				end if;			
				
				tank_A_pos(1) <= tank_A_pos_in(1);
				tank_B_pos(1) <= tank_B_pos_in(1);
			else 								--write state
				--tank A
				if ((tank_A_pos(0) - tank_width/2) >= tank_width_buffer and (tank_A_pos(0) + tank_width/2) < (679 - tank_width_buffer)) then  
					--tank within bounds
					tank_A_pos_out(0) <= tank_A_pos(0);
				else
					--tank out of bounds
					if ((tank_A_pos(0) + tank_width/2) > (679 - tank_width_buffer)) then --position beyond right bound
						tank_A_pos_out(0) <= 679 - tank_width_buffer - tank_width/2;
					else --position beneath left bound
						tank_A_pos_out(0) <= 0 + tank_width_buffer + tank_width/2;
					end if;
				end if; 
				
				--tank B
				if ((tank_B_pos(0) - tank_width/2) >= tank_width_buffer and (tank_B_pos(0) + tank_width/2) < (679 - tank_width_buffer)) then  
					--tank within bounds
					tank_B_pos_out(0) <= tank_B_pos(0);
				else
					--tank out of bounds
					if ((tank_B_pos(0) + tank_width/2) > (679 - tank_width_buffer)) then --position beyond right bound
						tank_B_pos_out(0) <= 679 - tank_width_buffer - tank_width/2;
					else --position beneath left bound
						tank_B_pos_out(0) <= 0 + tank_width_buffer + tank_width/2;
					end if;
				end if; 

				tank_A_pos_out(1) <= tank_A_pos(1); --fixed vertical value
				tank_B_pos_out(1) <= tank_B_pos(1); --fixed vertical value
			end if;

		end if;
	end process;
	
	bullet_update : process(clk, rst) is
		variable bullet_A_temp, bullet_B_tmep : integer;
	begin
		if (rising_edge(clk)) then
			if (global_write_enable = '0') then --read state
				bullet_A_fired <= bullet_A_fired_in;
				bullet_A_pos <= bullet_A_pos_in + bullet_speed;
				bullet_B_fired <= bullet_B_fired_in;
				bullet_B_pos <= bullet_B_pos_in - bullet_speed;
			else --write state
				if () then
					-- collision detected, bullet A hit tank B
					score_A <= score_A + 1;
					--don't show bullet
				elsif (bullet_A_fired = '0' and player_A_fire = '1') then
					--player first fires bullet
					bullet_A_pos_out <= tank_A_pos;
					--show bullet
				elsif (bullet_A_fired = '1') then
					bullet_A_pos_out <= bullet_A_pos;
					--show bullet
				end if;
				
				
			end if;
		end if;
	end process;
	
architecture behavioral;