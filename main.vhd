library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
    Port ( clk : in  STD_LOGIC;
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC;
           pen_irq : out STD_LOGIC;
           btn : in STD_LOGIC;
           en_out : out STD_LOGIC;
           dis_btn : in STD_LOGIC);
end main;

architecture Behavioral of main is
  component command_responder is
       Port ( clk : in  STD_LOGIC;
       
           x_val : in  STD_LOGIC_VECTOR (11 downto 0);
           y_val : in  STD_LOGIC_VECTOR (11 downto 0);
           cmd : out STD_LOGIC_VECTOR (7 downto 0);
           cmd_flag : out STD_LOGIC;
           
           sclk : in  STD_LOGIC;
           en : in  STD_LOGIC;
           di : in  STD_LOGIC;
           do : out  STD_LOGIC);
   end component;
   
   signal x_val : STD_LOGIC_VECTOR (11 downto 0) := X"CCC";
   signal y_val : STD_LOGIC_VECTOR (11 downto 0) := X"555";
   signal cmd_flag : STD_LOGIC;
   signal cmd : STD_LOGIC_VECTOR (7 downto 0);
   
   --type X_COORD is integer range 0 to 255;
   --type Y_COORD is integer range 0 to 255;
   --type TOUCH_FLAG is std_logic;
   
   type VAL_BUFFER is array(0 to 31) of integer range 0 to 4095;
   type TOUCH_BUFFER is array(0 to 31) of std_logic;
   
   signal x_buffer : VAL_BUFFER;
   signal y_buffer : VAL_BUFFER;
   signal touch_buf : TOUCH_BUFFER;
   
   signal buffer_tail : integer range 0 to 31 := 0;
   signal buffer_head : integer range 0 to 31 := 0;
   signal queue_active : std_logic := '0';
   
   signal prev_cmd_flag : std_logic := '0';
   signal wait_frame_end : std_logic := '0';
   signal btn_buffer : std_logic_vector (7 downto 0) := "00000000";
   signal prev_btn : std_logic := '0';
   
   signal frame_timer : integer range 0 to 160000 := 0;
   signal frame_timer_active : std_logic := '0';
   signal frame_toggle : std_logic := '0';
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
  
  process (clk) is
  begin
    if (clk'event and clk = '1') then
      if (frame_timer_active = '1') then
        if (frame_timer = 160000) then
          frame_timer <= 0;
          frame_timer_active <= '0';
          
          frame_toggle <= not frame_toggle;
          
          -- move to the next entry in the buffer
          if (queue_active = '1') then
            if (buffer_head = 4) then
              queue_active <= '0';
              buffer_head <= 0;
            else
              buffer_head <= buffer_head + 1;
            end if;
          end if;
        else
          frame_timer <= frame_timer + 1;
        end if;
      end if;
    
      if (cmd_flag = '1' and prev_cmd_flag = '0') then
        prev_cmd_flag <= '1';
        if (cmd = X"84") then
          frame_timer <= 0;
          frame_timer_active <= '1';
        end if;
      
      elsif (cmd_flag = '0' and prev_cmd_flag = '1') then
        prev_cmd_flag <= '0';
      end if;
      
      if (prev_btn = '0' and btn_buffer = "11111111") then
        -- reset the queue pointer
        buffer_head <= 0;
        queue_active <= '1';
        
        -- set some values in the queue
        x_buffer(0) <= 2986;
        y_buffer(0) <= 1131;
        touch_buf(0) <= '0';
        
        x_buffer(1) <= 2286;
        y_buffer(1) <= 1131;
        touch_buf(1) <= '0';
        
        x_buffer(2) <= 2286;
        y_buffer(2) <= 2081;
        touch_buf(2) <= '1';
        
        x_buffer(3) <= 1586;
        y_buffer(3) <= 2081;
        touch_buf(3) <= '0';
        
        x_buffer(4) <= 1586;
        y_buffer(4) <= 2081;
        touch_buf(4) <= '0';
        
        frame_timer <= 0;
        frame_timer_active <= '0';
                
        prev_btn <= '1';
      elsif (prev_btn = '1' and btn_buffer = "00000000") then
        prev_btn <= '0';
      end if;
      
      btn_buffer <= btn_buffer(6 downto 0) & btn;
    end if;
  end process;
  
  -- x_val <= something from the buffer, or 0
  -- y_val <= something from the buffer, or 0
  -- pen_irq <= 1 from the buffer, or 'Z'
  
  -- monitor cmd flag
    -- 0x84 will be sent every frame
    -- When the game polls for input, sequence will be:
      -- 0x84, 0xD1, 0xD1, 0xD1, 0xD1, 0xD1, 0xD1, 0x91, 0x91, 0x91, 0x91, 0x91, 0x91, 0x84
  -- wait for a 0x91
    -- then next 0x84 will indicate the end of the frame
  
  -- store x and y values for cmd_handler
  -- pull IRQ low
  
  -- when the data is polled, do the next frame of data, or release input
 
  x_val <= std_logic_vector(to_unsigned(x_buffer(buffer_head), 12)) when queue_active = '1'
      else "000000000000";
  y_val <= std_logic_vector(to_unsigned(y_buffer(buffer_head), 12)) when queue_active = '1'
      else "000000000000";
  
  pen_irq <= touch_buf(buffer_head) when queue_active = '1' and touch_buf(buffer_head) = '0' 
        else 'Z';

  en_out <= en when dis_btn = '0' else '1';
end Behavioral;

