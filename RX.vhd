library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity RX is
  port (
    clk : in std_logic;
	 rst : in std_logic;
    rx : in std_logic;
    data : out std_logic_vector(7 downto 0);
    valid : out std_logic;
    stop_bit_error : out std_logic
  );
end RX; 
 
architecture rtl of RX is
 
  type state_type is (
    DETECT_START,
    WAIT_START,
    WAIT_HALF_BIT,
    SAMPLE_DATA,
    WAIT_STOP,
    CHECK_STOP);
  signal state : state_type;
 
  -- For counting clock periods
  constant clock_cycles_per_bit : integer := integer(real(50.0e6) / real(9600));
  subtype clk_counter_type is integer range 0 to clock_cycles_per_bit - 1;
  signal clk_counter : clk_counter_type;
 
  -- For counting the number of transmitted bits
  signal bit_counter : integer range data'range;
 
  -- The rx signal delayed by one clock cycle
  signal rx_p1 : std_logic;
 
  signal shift_reg : std_logic_vector(data'range);
 
begin
 
  FSM_PROC : process(clk)
  begin
    if rising_edge(clk) then
		 if rst = '1' then
        data <= (others => '0');
        valid <= '0';
        stop_bit_error <= '0';
        state <= DETECT_START;
        clk_counter <= 0;
        rx_p1 <= '0';
        bit_counter <= 0;
        shift_reg <= (others => '0');
		  
	 else
	 
        valid <= '0';
 
        rx_p1 <= rx;
 
        case state is
           
          -- Wait for the falling edge on rx
          when DETECT_START =>
            if rx = '0' and rx_p1 = '1' then
              state <= WAIT_START;
              clk_counter <= 1;
              stop_bit_error <= '0';
            end if;
 
          -- Wait for the duration of the start bit
          when WAIT_START =>
            if clk_counter = clk_counter_type'high then
              state <= WAIT_HALF_BIT;
              clk_counter <= 0;
            else
              clk_counter <= clk_counter + 1;
            end if;
 
          -- Wait until we are at the middle of data bit 0
          when WAIT_HALF_BIT =>
            if clk_counter = clk_counter_type'high / 2 then
              state <= SAMPLE_DATA;
              clk_counter <= clk_counter_type'high;
            else
              clk_counter <= clk_counter + 1;
            end if;
 
          -- Sample all data bits
          when SAMPLE_DATA =>
            if clk_counter = clk_counter_type'high then
              clk_counter <= 0;
 
              -- Shift the data in from high to low index
              shift_reg(shift_reg'high) <= rx;
              for i in shift_reg'high downto shift_reg'low + 1 loop
                shift_reg(i - 1) <= shift_reg(i);
              end loop;
 
              if bit_counter = data'high then
                state <= WAIT_STOP;
                bit_counter <= 0;
              else
                bit_counter <= bit_counter + 1;
              end if;
 
            else
              clk_counter <= clk_counter + 1;
            end if;
 
          -- Wait for the duration of the stop bit
          when WAIT_STOP =>
            if clk_counter = clk_counter_type'high then
              state <= CHECK_STOP;
              clk_counter <= 0;
            else
              clk_counter <= clk_counter + 1;
            end if;
 
          -- Check that the stop bit is '1' and output data
          when CHECK_STOP =>
            state <= DETECT_START;
            data <= shift_reg;
            valid <= '1';
            shift_reg <= (others => '0');
 
            if rx = '0' then
              stop_bit_error <= '1';
            end if;
 
        end case;
       end if;
    end if;
  end process; -- FSM_PROC
 
end architecture;