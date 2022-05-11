library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Use ieee.std_logic_unsigned.all;

library Motor;

entity top is
port (
	-- Input signals
	CLK		: in std_logic;	-- System clock (50MHz)
	KEY		: in std_logic_vector(3 downto 0);
	SW			: in std_logic_vector(17 downto 16);
	
	-- UART inteface
	UART_RXD : in std_logic;
	
	-- Output signals
	LEDG 	 : out std_logic_vector(7 downto 0);
	LEDR	 : out std_logic_vector(17 downto 0);
	GPIO_1 : out std_logic_vector(3 downto 0)	-- Output for GPIO
	);
end top;

architecture str of top is
	
	signal rst : std_logic;
	
	signal char_buf_out	: std_logic_vector(7 downto 0);
	
	-- RX signals
	signal RX_DATA  : std_logic_vector(7 downto 0);
	signal RX_VALID  : std_logic;
	signal RX_STOP	 : std_logic;

---------------------------------------------------------------------------------------------
  begin
  
	RESET : entity Motor.reset(rtl)
	 port map (
    clk => clk,
    rst_in => KEY(0),
    rst_out => rst
  );
	UART_RX_INST : entity Motor.RX(rtl)
	port map (
	 clk	=> CLK,
	 rst 	=> rst,
    rx 	=> UART_RXD,
    data => RX_DATA,
    valid => RX_VALID,
    stop_bit_error => RX_STOP
	);
  
	CHAR_BUF : entity Motor.char_buf(rtl)
	port map (
    clk => CLK,
    rst => rst,
    wr  => RX_VALID,
    din => RX_DATA,
    dout => char_buf_out
	);
	
	CONTROLLER : entity Motor.controller(rtl)
	port map (		
	clk	=> CLK,
	rst	=> rst,
	sw17	=> SW(17), 
	sw16	=> SW(16),
	uart_data => RX_DATA,
	ledr17	=> LEDR(17), 
	ledr16	=> LEDR(16),
	gpio_output => GPIO_1,
	ledr_output	=> LEDR(7 downto 0)
	);
  process(RX_VALID)
  begin
    if(RX_VALID'EVENT and RX_VALID = '1') then
      LEDG(7 downto 0) <= RX_DATA;	-- LED Green display data value
    end if;
  end process;
end architecture;