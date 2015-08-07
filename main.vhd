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
           cmd : out STD_LOGIC_VECTOR (7 downto 0);
           cmd_flag : out STD_LOGIC;
           
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC);
   end component;
   
   signal x_val : STD_LOGIC_VECTOR (15 downto 0) := X"CCCC";
   signal y_val : STD_LOGIC_VECTOR (15 downto 0) := X"5555";
   signal cmd_flag : STD_LOGIC;
   signal cmd : STD_LOGIC_VECTOR (7 downto 0);
begin
  cmd_handler: command_responder port map (clk => clk,
                                           x_val => x_val,
                                           y_val => y_val,
                                           cmd_flag => cmd_flag,
                                           cmd => cmd,
                                           sclk => sclk,
                                           en => en,
                                           di => di,
                                           do => do);

end Behavioral;

