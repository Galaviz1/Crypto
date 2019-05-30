-- Standard VHDL Synthesis Packages. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.mars_pack.all;

-- ===========================================================================
-- =========================== Interface Description =========================
-- ===========================================================================

entity ALG_ITERATIVE is

  port (clock       :  in STD_LOGIC;
        reset       :  in STD_LOGIC;

        ALG_DATAIN  :  in SLV_128;
        SUBKEYS     :  in K_ARRAY_TYPE;
        ALG_START   :  in STD_LOGIC;
        ALG_ENC     :  in STD_LOGIC;

        ALG_DATAOUT :  out SLV_128;
        ALG_DONE    :  out STD_LOGIC
  );

end ALG_ITERATIVE;

architecture ALG_ITERATIVE_RTL of ALG_ITERATIVE is


-- ===========================================================================
-- =========================== Constant Definition ===========================
-- ===========================================================================

constant HOLD : integer := 0;         -- Hold state for controller

-- ===========================================================================
-- =========================== Signal Definition =============================
-- ===========================================================================

signal ROUND           : ROUND_TYPE;     -- round number
signal D_REG           : SLV_128;        -- data out from round i

begin

ALG_DATAOUT <= D_REG(31 downto 0) &
               D_REG(63 downto 32) &
               D_REG(95 downto 64) &
               D_REG(127 downto 96)
  when (ALG_ENC = '1' and ROUND = LAST_ROUND+1) else D_REG
  when (ALG_ENC = '0' and ROUND = LAST_ROUND+1) else (others => '0');


-- ===========================================================================
-- =========================== Data Movement =================================
-- ===========================================================================

DATA_FLOW: process( clock, reset )

begin

if reset = '1' then                        -- check for reset condition

   D_REG    <= ( others => '0' );          -- clear round key outputs
   ALG_DONE <= '0';                        -- clear done signal

elsif clock'event and clock = '1' then     -- rising edge clock

   if ALG_START = '1' then

      KEY_ADD( ALG_DATAIN,
               SUBKEYS(0),
               SUBKEYS(1),
               SUBKEYS(2),
               SUBKEYS(3),
               SUBKEYS(36),
               SUBKEYS(37),
               SUBKEYS(38),
               SUBKEYS(39),
               ALG_ENC,
               D_REG );
 
   end if;

   case ROUND is

    when 1|2|3|4|5|6|7|8 =>
      FORWARD_UNKEYED_ROUND( D_REG,
                             ALG_ENC, 
                             std_logic_vector(TO_UNSIGNED(ROUND,6)), 
                             D_REG );

    when 9|10|11|12|13|14|15|16 =>
      FORWARD_KEYED_ROUND( D_REG,
                           SUBKEYS(2*ROUND-14),
                           SUBKEYS(2*ROUND-13),
                           SUBKEYS(52-2*ROUND),
                           SUBKEYS(53-2*ROUND),
                           ALG_ENC,
                           std_logic_vector(TO_UNSIGNED(ROUND,6)),
                           D_REG );

    when 17|18|19|20|21|22|23|24 =>
      BACKWARD_KEYED_ROUND( D_REG,
                            SUBKEYS(2*ROUND-14),
                            SUBKEYS(2*ROUND-13),
                            SUBKEYS(52-2*ROUND),
                            SUBKEYS(53-2*ROUND),
                            ALG_ENC,
                            D_REG );

    when 25|26|27|28|29|30|31|32 =>
      BACKWARD_UNKEYED_ROUND( D_REG,
                              ALG_ENC,
                              std_logic_vector(TO_UNSIGNED(ROUND,6)),
                              D_REG );

    when LAST_ROUND =>

      KEY_SUB( D_REG,
               SUBKEYS(36),
               SUBKEYS(37),
               SUBKEYS(38),
               SUBKEYS(39),
               SUBKEYS(3),
               SUBKEYS(2),
               SUBKEYS(1),
               SUBKEYS(0),
               ALG_ENC,
               D_REG );

      ALG_DONE <= '1';
  
    when others =>

      ALG_DONE    <= '0';
    
    end case;        

end if; 

end process; -- DATA_FLOW


-- ===========================================================================
-- =========================== State Machine / Controller ====================
-- ===========================================================================

STATE_FLOW: process( clock, reset )

variable active : std_logic;                -- Indicates whether algorithm is
                                            -- active (1) or in hold (0)

begin

if reset = '1' then                         -- Active high reset (asynch)

   ROUND  <= HOLD;                          -- put controller in hold state
   active := '0';                           -- stop process until ALG_START=1

elsif clock'event and clock = '1' then      -- check for rising edge clock

   if  ( ALG_START = '1' or active = '1' )  -- check for inactive  
   and ( ROUND /= LAST_ROUND+1 ) then       -- and completion of algorithm

      active := '1';                        -- enable controller
      ROUND  <= ROUND + 1;                  -- active, so increment counter

   else

      active := '0';                        -- disable controller
      ROUND  <= HOLD;                       -- reset counter
             
   end if;

end if; -- reset

end process;

end ALG_ITERATIVE_RTL;
