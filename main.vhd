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
           --btn : in STD_LOGIC;
           en_out : out STD_LOGIC;
           dis_btn : in STD_LOGIC;
           RX: in STD_LOGIC;
           TX: out STD_LOGIC;
           l: out STD_LOGIC_VECTOR(3 downto 0));
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
   
   	component UART is
    Port ( rx_data_out : out STD_LOGIC_VECTOR (7 downto 0);
           rx_data_was_recieved : in STD_LOGIC;
           rx_byte_waiting : out STD_LOGIC;
           clk : in  STD_LOGIC;

           rx_in : in STD_LOGIC;
           tx_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           tx_buffer_full : out STD_LOGIC;
           tx_write : in STD_LOGIC;
           tx_out : out STD_LOGIC);
    end component;
  
   signal data_from_uart : STD_LOGIC_VECTOR (7 downto 0);
   signal uart_data_recieved : STD_LOGIC := '0';
	 signal uart_byte_waiting : STD_LOGIC := '0';
   
   signal data_to_uart : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	 signal uart_buffer_full : STD_LOGIC;
	 signal uart_write : STD_LOGIC := '0';
   
   
   signal uart_buffer_ptr : integer range 0 to 7 := 0;
   signal uart_touch_val : std_logic := '0';
   signal uart_x_val : std_logic_vector(11 downto 0) := x"000";
   signal uart_y_val : std_logic_vector(11 downto 0) := x"000";
   
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
   
   signal prev_cmd_flag : std_logic := '0';
   signal wait_frame_end : std_logic := '0';
   signal btn_buffer : std_logic_vector (7 downto 0) := "00000000";
   signal prev_btn : std_logic := '0';
   
   signal frame_timer : integer range 0 to 160000 := 0;
   signal frame_timer_active : std_logic := '0';
   signal frame_toggle : std_logic := '0';
   
   signal last_data : std_logic_vector(3 downto 0) := "0000";
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
  
  uart1: UART port map (rx_data_out => data_from_uart,
                       rx_data_was_recieved => uart_data_recieved,
                       rx_byte_waiting => uart_byte_waiting,
                       clk => CLK,
                       rx_in => RX,
                       tx_data_in => data_to_uart,
                       tx_buffer_full => uart_buffer_full,
                       tx_write => uart_write,
                       tx_out => TX);

uart_recieve_btye: process(CLK)
  variable hex_val : std_logic_vector(3 downto 0);
	begin
		if (rising_edge(CLK)) then
			if (uart_byte_waiting = '1' and uart_data_recieved = '0') then
				case data_from_uart is
          when x"66" => -- 'f'
            -- Commit values in buffer to queue
            -- make sure there is room
            if ((buffer_head = 31 and buffer_tail /= 0) or (buffer_head /= 31 and (buffer_head + 1) /= buffer_tail)) then
              -- add it to the next spot
              x_buffer(buffer_head) <= to_integer(unsigned(uart_x_val));
              y_buffer(buffer_head) <= to_integer(unsigned(uart_y_val));
              touch_buf(buffer_head) <= uart_touch_val;
              
              -- move
              if (buffer_head = 31) then
                buffer_head <= 0;
              else
                buffer_head <= buffer_head + 1;
              end if;
            end if;

            -- reset the buffer pointer to 0
            uart_buffer_ptr <= 0;
            
            last_data <= "1111";
          when x"63" => -- 'c'
            uart_buffer_ptr <= 0;
            
          when others =>
            case uart_buffer_ptr is
              when 0 =>
                case data_from_uart is 
                  when x"59" => -- 'Y'
                    uart_touch_val <= '1';
                    uart_buffer_ptr <= uart_buffer_ptr + 1;
                    
                    last_data <= "1010";
                  when x"4E" => -- 'N'
                    uart_touch_val <= '0';
                    uart_buffer_ptr <= uart_buffer_ptr + 1;
                    
                    last_data <= "0101";
                  when others =>
                  
                end case; 
              when 1 to 6 =>
                if ((data_from_uart >= x"30" and data_from_uart <= x"39") or (data_from_uart >= x"41" and data_from_uart <= x"46")) then
                  case data_from_uart is
                    when x"30" =>
                      hex_val := "0000";
                    when x"31" =>
                      hex_val := "0001";
                    when x"32" =>
                      hex_val := "0010";
                    when x"33" =>
                      hex_val := "0011";
                    when x"34" =>
                      hex_val := "0100";
                    when x"35" =>
                      hex_val := "0101";
                    when x"36" =>
                      hex_val := "0110";
                    when x"37" =>
                      hex_val := "0111";
                    when x"38" =>
                      hex_val := "1000";
                    when x"39" =>
                      hex_val := "1001";
                    when x"41" =>
                      hex_val := "1010";
                    when x"42" =>
                      hex_val := "1011";
                    when x"43" =>
                      hex_val := "1100";
                    when x"44" =>
                      hex_val := "1101";
                    when x"45" =>
                      hex_val := "1110";
                    when x"46" =>
                      hex_val := "1111";
                    when others =>
                    
                  end case;
                  
                  last_data <= hex_val;
                  
                  case uart_buffer_ptr is
                    when 1 =>
                      uart_x_val(11 downto 8) <= hex_val;
                    when 2 =>
                      uart_x_val(7 downto 4) <= hex_val;
                    when 3 =>
                      uart_x_val(3 downto 0) <= hex_val;
                    when 4 =>
                      uart_y_val(11 downto 8) <= hex_val;
                    when 5 =>
                      uart_y_val(7 downto 4) <= hex_val;
                    when 6 =>
                      uart_y_val(3 downto 0) <= hex_val;
                    when others =>
                    
                  end case;
                  
                  uart_buffer_ptr <= uart_buffer_ptr + 1;
                end if;
              when others =>
                
            end case;
				end case;
				uart_data_recieved <= '1';
			else
				uart_data_recieved <= '0';
			end if;
		end if;
	end process;
  
  l <= std_logic_vector(to_unsigned(buffer_tail, 4));--last_data;

  
  process (clk) is
  begin
    if (clk'event and clk = '1') then
      if (frame_timer_active = '1') then
        if (frame_timer = 160000) then
          frame_timer <= 0;
          frame_timer_active <= '0';
          
          frame_toggle <= not frame_toggle;
          
          -- move tail pointer if possible
          if (buffer_tail /= buffer_head) then
            if (buffer_tail = 31) then
              buffer_tail <= 0;
            else
              buffer_tail <= buffer_tail + 1;
            end if;
            
            -- Send feedback that a frame was consumed
            if (uart_buffer_full = '0') then
              uart_write <= '1';
              data_to_uart <= x"66";
              
            end if;
          end if;
        else
          frame_timer <= frame_timer + 1;
        end if;
      else
        uart_write <= '0';
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
      
--      if (prev_btn = '0' and btn_buffer = "11111111") then
--        -- reset the queue pointer
--        buffer_tail <= 0;
--        buffer_head <= 4;
--        queue_active <= '1';
--        
--        -- set some values in the queue
--        x_buffer(0) <= 2986;
--        y_buffer(0) <= 1131;
--        touch_buf(0) <= '0';
--        
--        x_buffer(1) <= 2286;
--        y_buffer(1) <= 1131;
--        touch_buf(1) <= '0';
--        
--        x_buffer(2) <= 2286;
--        y_buffer(2) <= 2081;
--        touch_buf(2) <= '1';
--        
--        x_buffer(3) <= 1586;
--        y_buffer(3) <= 2081;
--        touch_buf(3) <= '0';
--        
--        x_buffer(4) <= 1586;
--        y_buffer(4) <= 2081;
--        touch_buf(4) <= '0';
--        
--        frame_timer <= 0;
--        frame_timer_active <= '0';
--                
--        prev_btn <= '1';
--      elsif (prev_btn = '1' and btn_buffer = "00000000") then
--        prev_btn <= '0';
--      end if;
--      
--      btn_buffer <= btn_buffer(6 downto 0) & btn;
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
 
 
  -- send the last frame, unless we have new data
  x_val <= std_logic_vector(to_unsigned(x_buffer(buffer_tail), 12)) when buffer_head /= buffer_tail else
           std_logic_vector(to_unsigned(x_buffer(31), 12)) when buffer_tail = 0 else
           std_logic_vector(to_unsigned(x_buffer(buffer_tail - 1), 12));
           
  y_val <= std_logic_vector(to_unsigned(y_buffer(buffer_tail), 12)) when buffer_head /= buffer_tail else
           std_logic_vector(to_unsigned(y_buffer(31), 12)) when buffer_tail = 0 else
           std_logic_vector(to_unsigned(y_buffer(buffer_tail - 1), 12));
  
  pen_irq <= not touch_buf(buffer_tail) when buffer_head /= buffer_tail else
             not touch_buf(31) when buffer_tail = 0 else
             not touch_buf(buffer_tail - 1);

--  x_val <= std_logic_vector(to_unsigned(x_buffer(buffer_tail), 12));
--           
--  y_val <= std_logic_vector(to_unsigned(y_buffer(buffer_tail), 12));
--  
--  pen_irq <= touch_buf(buffer_tail);


  -- disable the chip for now
  en_out <= '1'; -- en when dis_btn = '0' else '1';
end Behavioral;

