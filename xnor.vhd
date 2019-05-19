-- Standard VHDL Synthesis Packages. 


library IEEE;
use IEEE.std_logic_1164.all;

package numeric_std is
    constant CopyRightNotice: STRING
       := "Copyright (c) Alex G. All rights reserved.";

--===========================================================================
  -- Numeric array type definitions
 
--===========================================================================

    type UNSIGNED is array (NATURAL range <>) of STD_LOGIC;
    type SIGNED is array (NATURAL range <>) of STD_LOGIC;
