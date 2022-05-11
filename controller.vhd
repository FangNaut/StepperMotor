---------------------------------------------------------------------------------------------
-- Note : Find the way to reset j = 0 after finish rotate OR update i
----------------------------------------------------------------------------------------------

Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.std_logic_unsigned.all;
Use ieee.numeric_std.all;

entity controller is
port (
	-- Input signal		
	clk	:	in std_logic;	-- System clock (50MHz)
	rst   :  in std_logic;
	sw17, sw16 	: in std_logic;
	
	-- UART inteface
	uart_data : in std_logic_vector(7 downto 0);		-- Connect to RX_DATA
	
	-- Output signal
	ledr17, ledr16	: out std_logic;
	gpio_output : out std_logic_vector(3 downto 0);	-- Output for GPIO
	ledr_output	: out std_logic_vector(7 downto 0)	-- Output for red LEDs
	);
end controller;

architecture rtl of controller is

	signal count		: std_logic_vector(25 downto 0);	-- Clock divider
	signal selection 	: std_logic_vector(1 downto 0);
	
	-- ROM for step sequence -----------------------------------------
	type step_type is array (0 to 3) of std_logic_vector(3 downto 0);
	  constant step : step_type := (	
		("0110"),
		("0101"),
		("1001"),
		("1010")	
	);
	------------------------------------------------------------------
	
	constant rom : step_type := step;
	
	
	-- The number of step left to move before stopping
	signal step_left : std_logic_vector(7 downto 0);
	signal i : integer;
	signal j : integer := 0; 
	
	begin
		------------------------------------------------
				ledr17 <= sw17;
				ledr16 <= sw16;
		------------------------------------------------		
		process(clk)
		begin
		
			if rising_edge(clk) then
				if rst = '1' then
					step_left <= (others => '0');
					j <= 0;
				else
				step_left <= std_logic_vector(to_unsigned(to_integer(unsigned(uart_data)) - 48, step_left'length));
					
					
				i <= to_integer(unsigned(step_left)) * 48;		-- 1 rotation contains 48 steps
					
				if step_left = "11010000" then	-- This statement make motor stay still and wait for data come when start up
					gpio_output <= (others => '0');
				else
					ledr_output <= step_left;
				-------------------------------

				-------------------------------
				if (count < 1999999) then	-- 1 execute per second --
														-- count = ( 50 MHz / desired freq ) - 1
						count <= count + "1";
	
				else
					count <= (others => '0');

					
					-------------------------------------------------------------------
					-- Assign value for gpio_output and ledr_output
					-- Step |     CW    | CCW  |	Signal
					--  1   |    0110	  | 1010 | 	 00
					--  2	  |	 0101   | 1001 |   01
					--  3   |	 1001   | 0101 |   10
					--  4   |    1010   | 0110 |   11
					--  1   |    0110   | 1010 |   00	
		
				if j >= 0 then
					if j = i then
						gpio_output <= (others => '0');
					else
						
						-- SW17 control motor direction
						if (sw17 = '1') then 
							selection <= selection - "01";	-- Direction : Counter Clockwise
						elsif (sw17 = '0') then 
							selection <= selection + "01"; 	-- Direction : Clockwise
						end if;	
		

						-- SW16 control motor ON/OFF
						if (sw16 = '1') then
							gpio_output <= (others => '0');
							ledr_output <= (others => '0');
						else
		
						
						-- Start CASE selection
						case selection is	
							when "00" =>
									gpio_output   <= rom(0);
							when "01" =>
									gpio_output   <= rom(1);								
							when "10" =>
									gpio_output   <= rom(2);								
							when "11" =>
									gpio_output   <= rom(3);
							when others =>
								gpio_output   <= (others => '0');

						end case;	
		
						end if;
						
							if j < i then
								j <= j + 1;	
							elsif j > i then 
								j <= j - 1;
							end if;
							
					 end if;

				end if;
				end if;
				end if;
				end if;
			end if;
		end process;
		
end architecture rtl;