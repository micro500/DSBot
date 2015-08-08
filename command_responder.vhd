library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity command_responder is
    Port ( clk : in  STD_LOGIC;
    
           x_val : in  STD_LOGIC_VECTOR (11 downto 0);
           y_val : in  STD_LOGIC_VECTOR (11 downto 0);
           
           cmd : out STD_LOGIC_VECTOR (7 downto 0);
           cmd_flag : out STD_LOGIC;
           
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC);
end command_responder;

architecture Behavioral of command_responder is
  signal in_buffer : std_logic_vector(7 downto 0) := "00000000";
  
  signal out_buffer : std_logic_vector(16 downto 0) := "00000000000000000";
  
  signal prev_en : std_logic := '1';
  signal prev_sclk : std_logic := '1';
  
  signal en_buf : std_logic_vector(2 downto 0) := "111";
  signal sclk_buf : std_logic_vector(2 downto 0) := "111";
  
  signal debug : std_logic := '0';
begin
  process (clk) is
  begin
    
    if (clk'event and clk = '1') then
      -- On falling edge of enable
      en_buf <= en_buf(1 downto 0) & en;
      if (en_buf = "000" and prev_en = '1') then
        -- Clear the buffers
        in_buffer <= "00000000";
        out_buffer <= "00000000000000000";
        prev_en <= '0';
      elsif (en_buf = "111" and prev_en = '0') then
        prev_en <= '1';
      end if;
      
      if (en = '0') then
        sclk_buf <= sclk_buf(1 downto 0) & sclk;
      
        -- Falling edge of sclk
        if (sclk_buf= "000" and prev_sclk = '1') then
          prev_sclk <= '0';
          out_buffer <= out_buffer(15 downto 0) & '0';
          
        -- Rising edge of sclk
        elsif (sclk_buf = "111" and prev_sclk = '0') then
          cmd_flag <= '0';
          in_buffer <= in_buffer(6 downto 0) & di;
          prev_sclk <= '1';
          debug <= not debug;
        end if;
        
        if (in_buffer = X"84" or in_buffer = X"D1" or in_buffer = X"91") then
          if (in_buffer = X"84") then
            out_buffer <= '0' & "0001011101000000";
          elsif (in_buffer = X"D1") then
            out_buffer <= "00" & x_val & "000";
          elsif (in_buffer = X"91") then
            out_buffer <= "00" & y_val & "000";
          end if;
          
          cmd <= in_buffer;
          cmd_flag <= '1';
          in_buffer <= "00000000";
          
        end if;
      end if;
    end if;
  end process;

  do <= out_buffer(16) when en = '0'
        else 'Z';
        
end Behavioral;

