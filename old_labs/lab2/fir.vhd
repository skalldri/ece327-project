------------------------------------------------------------------------
-- finite-impulse response filters
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fir_synth_pkg.all;

entity fir is
  port(
    clk     : in  std_logic;
    i_data  : in  word;
    o_data  : out word
  );
end entity;

architecture avg of fir is

  signal tap0, tap1 , tap2 , tap3 , tap4
             , prod1, prod2, prod3, prod4
                    , sum2 , sum3 , sum4
       : word;

  constant coef1 : word := x"0400";
  constant coef2 : word := x"0400";
  constant coef3 : word := x"0400";
  constant coef4 : word := x"0400";
  
  --constant coef1 : word := x"0200";
  --constant coef2 : word := x"0300";
  --constant coef3 : word := x"0400";
  --constant coef4 : word := x"0500";
  
begin

  -- delay line of flops to hold samples of input data
  tap0 <= i_data;
  delay_line : process(clk)
  begin
    if (rising_edge(clk)) then
      tap1 <= tap0;
      tap2 <= tap1;
      tap3 <= tap2;
      tap4 <= tap3;
    end if;
  end process;
  
  -- simple averaging circuit
  --
  -- Note that mult is a quick 'n' dirty multiplier
  -- However, a multiplier is NOT built in hardware because one input is a particular
  --  constant allowing optimizations to be done.  If you had to multiply by 2 or 4 or 16
  --  in hardware could you do it WITHOUT any adders, shifters or multipliers?
  --
  prod1 <= mult( tap1, coef1);
  prod2 <= mult( tap2, coef2);
  prod3 <= mult( tap3, coef3);
  prod4 <= mult( tap4, coef4);

  sum2  <= prod1 + prod2;
  sum3  <= sum2  + prod3;
  sum4  <= sum3  + prod4;
  
  o_data <= sum4;

end architecture;

------------------------------------------------------------------------
-- low-pass filter
------------------------------------------------------------------------

architecture low_pass of fir is

  -- Use the signal names tap, prod, and sum, but change the type to
  -- match your needs.
  
  signal tap, prod, sum : word_vector( 0 to num_taps );
  
  -- The attribute line below is usually needed to avoid a warning
  -- from PrecisionRTL that signals could be implemented using
  -- memory arrays.  

  attribute logic_block of tap, prod, sum : signal is true;

begin

  tap(0) <= i_data;

   -- delay line of flops to hold samples of input data
  GEN_DELAY : for i in 1 to num_taps generate
	  process(clk)
	  begin
	    if (rising_edge(clk)) then
		  tap(i) <= tap(i - 1);
		end if;
	  end process;
  end generate GEN_DELAY;
  
  -- simple averaging circuit
  --
  -- Note that mult is a quick 'n' dirty multiplier
  -- However, a multiplier is NOT built in hardware because one input is a particular
  --  constant allowing optimizations to be done.  If you had to multiply by 2 or 4 or 16
  --  in hardware could you do it WITHOUT any adders, shifters or multipliers?
  --
  GEN_MULT : for i in 1 to num_taps generate
	  prod(i) <= mult(tap(i), lpcoef(i));
  end generate GEN_MULT;

  sum(2)  <= prod(1) + prod(2);
  
  GEN_ADD : for i in 3 to num_taps generate
	  sum(i) <= sum(i - 1)  + prod(i);
  end generate GEN_ADD;
  
  o_data <= sum(num_taps);

end architecture;

-- question 2
  -- From the area report from the synthesis tool, the adders use either 15 or 16 LUTs each

-- question 3
  -- From the area report from the synthesis tool, the multipliers use 16 LUTs each
