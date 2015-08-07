library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity main is
    Port ( clk : in  STD_LOGIC;
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC;
           l : out STD_LOGIC_VECTOR(3 downto 0));
end main;

architecture Behavioral of main is
  component command_responder is
       Port ( clk : in  STD_LOGIC;
           x_val : in  STD_LOGIC_VECTOR (15 downto 0);
           y_val : in  STD_LOGIC_VECTOR (15 downto 0);
           frame_flag : out  STD_LOGIC;
           
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC;
           
           l : out STD_LOGIC_VECTOR(3 downto 0));
   end component;
   
   signal x_val : STD_LOGIC_VECTOR (15 downto 0);
   signal y_val : STD_LOGIC_VECTOR (15 downto 0);
   signal frame_flag : STD_LOGIC;
   
begin
  cmd_handler: command_responder port map (clk => clk,
                                           x_val => x_val,
                                           y_val => y_val,
                                           frame_flag => frame_flag,
                                           sclk => sclk,
                                           en => en,
                                           di => di,
                                           do => do,
                                           l => l);

end Behavioral;

