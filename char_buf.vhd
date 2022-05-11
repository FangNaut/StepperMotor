library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity char_buf is
  port (
    clk : in std_logic;
    rst : in std_logic;
    wr : in std_logic;
    din : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end char_buf; 
 
architecture rtl of char_buf is
 
begin
 
  SAMPLER_PROC : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dout <= (others => '0');
         
      else
        if wr = '1' then
          dout <= din;
        end if;
         
      end if;
    end if;
  end process; -- SAMPLER_PROC
 
end architecture;