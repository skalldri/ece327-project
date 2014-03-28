library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kirsch is
  port(
    ------------------------------------------
    -- main inputs and outputs
    i_clock    : in  std_logic;                      
    i_reset    : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  std_logic_vector(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out std_logic_vector(2 downto 0);                      
    o_mode     : out std_logic_vector(1 downto 0);
    o_row      : out std_logic_vector(7 downto 0);
    ------------------------------------------
    -- debugging inputs and outputs
    debug_key      : in  std_logic_vector( 3 downto 1) ; 
    debug_switch   : in  std_logic_vector(17 downto 0) ; 
    debug_led_red  : out std_logic_vector(17 downto 0) ; 
    debug_led_grn  : out std_logic_vector(5  downto 0) ;
    debug_num_0    : out std_logic_vector(3 downto 0) ; 
    debug_num_1    : out std_logic_vector(3 downto 0) ; 
    debug_num_2    : out std_logic_vector(3 downto 0) ; 
    debug_num_3    : out std_logic_vector(3 downto 0) ; 
    debug_num_4    : out std_logic_vector(3 downto 0) ;
    debug_num_5    : out std_logic_vector(3 downto 0) 
    ------------------------------------------
  );  
end entity;

architecture main of kirsch is

    -- A function to rotate left (rol) a vector by n bits  
    function "rol" ( a : std_logic_vector; n : natural )
        return std_logic_vector
    is
    begin
        return std_logic_vector( unsigned(a) rol n );
    end function;

    signal x_pos      : unsigned(7 downto 0) := to_unsigned(0, 8);
    signal y_pos      : unsigned(7 downto 0) := to_unsigned(0, 8);
    signal state      : unsigned(2 downto 0);

    signal v          : std_logic_vector(8 downto 0);
    
    signal a, b, c, d, e, f, g, h, i   : unsigned(11 downto 0);
    
    signal TMP1, TMP2, TMP3, TMP4      : unsigned(11 downto 0) := to_unsigned(0, 12);
    signal TMP5, TMP6, TMP7, TMP8      : unsigned(11 downto 0) := to_unsigned(0, 12);
    signal TMP9, TMP10, TMP11, TMP12   : unsigned(11 downto 0) := to_unsigned(0, 12);
    signal TMP13, TMP14, TMP15, TMP16  : unsigned(11 downto 0) := to_unsigned(0, 12);
    signal TMP17, TMP18, TMP19, TMP20  : unsigned(11 downto 0) := to_unsigned(0, 12);
	signal TMP2_2, TMP5_2, TMP11_2     : unsigned(11 downto 0) := to_unsigned(0, 12);
	signal TMP8_2, TMP12_2             : unsigned(11 downto 0) := to_unsigned(0, 12);
    
    signal DIR1, DIR2, DIR3, DIR4, DIR5, DIR6, DIR7  : std_logic_vector(2 downto 0);
    signal DIR1_2, DIR2_2, DIR3_2, DIR4_2            : std_logic_vector(2 downto 0);
	
    signal mem_1_wren : std_logic;
    signal mem_1_q    : std_logic_vector(7 downto 0);

    signal mem_2_wren : std_logic;
    signal mem_2_q    : std_logic_vector(7 downto 0);

    signal mem_3_wren : std_logic;
    signal mem_3_q    : std_logic_vector(7 downto 0);

begin  
    --instantiate the 3 instances of the memory module
    mem1 : entity work.mem(main)
     port map (
       address => std_logic_vector(x_pos),
       clock   => i_clock,
       data    => i_pixel,
       wren    => mem_1_wren,
       q       => mem_1_q
    );

    mem2 : entity work.mem(main)
     port map (
       address => std_logic_vector(x_pos),
       clock   => i_clock,
       data    => i_pixel,
       wren    => mem_2_wren,
       q       => mem_2_q
    );

    mem3 : entity work.mem(main)
     port map (
       address => std_logic_vector(x_pos),
       clock   => i_clock,
       data    => i_pixel,
       wren    => mem_3_wren,
       q       => mem_3_q
    );
	 
    --DEBUG
	--debug_led_red <= a & b & "00";
	--debug_led_grn <= "000" & std_logic_vector(state);
	
    -- Calculate the mem_x_wren signals
    -- We write data into a memory buffer all the time essentially, but we only change the write pos when we get i_valid
    -- This has the same effect as making the write-enable tied into the i_valid signal
    mem_1_wren <= '1' when state = 1 else '0';
	mem_2_wren <= '1' when state = 2 else '0';
	mem_3_wren <= '1' when state = 4 else '0';
			
    o_row <= std_logic_vector(y_pos);
   
    with v select
	 o_mode <= "10" when "000000000",
			   "11" when others;	
		 	
    -- Valid bit generator	
	v(0) <= i_valid;

    valid_for : for i in 1 to 8 generate
        process begin
            wait until rising_edge(i_clock);
            v(i) <= v(i-1);
        end process;
    end generate;
	
    -- Stage 1 pipeline
    --     This pipeline needs to clock the data into the x_2 registers before exiting
    process
    begin
        wait until rising_edge(i_clock);
        
		
		if i_reset = '1' then
			state <= to_unsigned(1, 3);
		end if;
		
        if v(3) = '1' then
		
			if e > h then
				TMP5 <= e + f + g; -- S
				DIR2 <= "011";
			else
				TMP5 <= h + f + g; -- SW
				DIR2 <= "111";
			end if;
			--TMP5 is max of S and SW
			
			--Set vars for stage 2
			TMP2_2 <= TMP2; --TMP2 is max of N and NE
			TMP5_2 <= TMP5; --TMP5 is max of S and SW
			TMP8_2 <= TMP8; --TMP8 is max of E, SE
			TMP11_2 <= TMP11; --TMP11 is max of W, NW
			TMP12_2 <= a + b + c + d + e + f + g + h;
            
            DIR1_2 <= DIR1;
            DIR2_2 <= DIR2;
            DIR3_2 <= DIR3;
            DIR4_2 <= DIR4;
			
		elsif v(2) = '1' then    
			if c > f then
				TMP8 <= c + d + e; -- E
				DIR3 <= "000";
			else
				TMP8 <= f + d + e; -- SE
				DIR3 <= "101";
			end if;
			--TMP8 is max of E, SE
		elsif v(1) = '1' then
			if a > d then
				TMP2 <= a + b + c; -- N
				DIR1 <= "010";
			else
				TMP2 <= d + b + c; -- NE
				DIR1 <= "110";
			end if;
			--TMP2 is max of N and NE  
		elsif v(0) = '1' then
			
			-- Grab the fresh cells from the correct memory buffer depending 
			-- on the value of state: 
			-- if we insert into memory buffer 3, 'e' is in buffer 3 so c is in buffer 1, etc...)
			b <= c;
			a <= b;

			i <= d;
			h <= i;

			f <= e;
			g <= f;

			-- e is always the most recently entered pixel: we go from [2, 2] to [255, 255] in the image processing (indexed from [0, 0])
			e <= unsigned("0000" & i_pixel);

			case state is
				when "001" =>
					d <= unsigned("0000" & mem_3_q);
				when "010" => 
					d <= unsigned("0000" & mem_1_q);
				when "100" => 
					d <= unsigned("0000" & mem_2_q);
				when others =>
					d <= to_unsigned(0, 12);
			end case;

			case state is
				when "001" =>
					c <= unsigned("0000" & mem_2_q);
				when "010" => 
					c <= unsigned("0000" & mem_3_q);
				when "100" => 
					c <= unsigned("0000" & mem_1_q);
				when others =>
					c <= to_unsigned(0, 12);
			end case;

			--Increment the x_pos and possibly y_pos
			if(x_pos = 255) then            
				y_pos <= y_pos + 1;
				state <= state ROL 1;
			end if;
			x_pos <= x_pos + 1;
			
			-- One square to the left because we're doing matrix shifts in this clock cycle
			if f > c then
				TMP11 <= f + i + b; -- W
				DIR4 <= "001";
			else
				TMP11 <= c + i + b; -- NW
				DIR4 <= "100";
			end if;
			--TMP11_2 is max of W, NW
        end if;
		
		if v(4) = '1' then
			
			if TMP8_2 > TMP5_2 then
				TMP14 <= TMP8_2; -- Max of E, SE
				DIR5 <= DIR3_2;
			else
				TMP14 <= TMP5_2; -- Max of S, SW
				DIR5 <= DIR2_2;
			end if;
			--TMP14 is Max of (E, SE), (S, SW)

        elsif v(5) = '1' then 
			TMP18 <= TMP12_2 ROL 1;
			
			if TMP11_2 > TMP2_2 then
				TMP17 <= TMP11_2; -- Max of W, NW
				DIR6 <= DIR4_2;
			else
				TMP17 <= TMP2_2; -- Max of N, NE
				DIR6 <= DIR1_2;
			end if;
			--TMP17 is Max of (W, NW), (N, NE)

        elsif v(6) = '1' then
		
			TMP19 <= TMP18 + TMP12_2;
		
			if TMP17 > TMP14 then
				TMP20 <= TMP17 ROL 3; -- Max of (W, NW), (N, NE)
				DIR7 <= DIR6;
			else
				TMP20 <= TMP14 ROL 3; -- Max of (E, SE), (S, SW)
				DIR7 <= DIR5;
			end if;
			--TMP20 is Max of ((W, NW), (N, NE)), ((E, SE), (S, SW))
        elsif v(7) = '1' then			
			if (TMP20 - TMP19) > 383 then
				o_edge <= '1';				 
				o_dir <= DIR7;
			else
				o_edge <= '0';				 
				o_dir <= "000";
			end if;
		end if;
		
		if (v(7) = '1' AND ((y_pos >= 2 AND x_pos >= 2) OR y_pos >= 3)) then
			o_valid <= '1';
		else
			o_valid <= '0';
		end if;
    end process;
end architecture;



