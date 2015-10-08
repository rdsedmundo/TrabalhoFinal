library ieee;
use ieee.std_logic_1164.all;

ENTITY SHIFT_REGISTER IS
   GENERIC(
      NUM_STAGES : NATURAL := 24
   );
   PORT (
      clk   : IN STD_LOGIC;
      enable: IN STD_LOGIC;
      dIn   : IN STD_LOGIC;
      dOut  : OUT STD_LOGIC_VECTOR((NUM_STAGES-1) DOWNTO 0)
   );

END ENTITY;

ARCHITECTURE ARCH_SHIFTREGISTER OF SHIFT_REGISTER IS
   TYPE sr_length IS ARRAY ((NUM_STAGES-1) DOWNTO 0) OF STD_LOGIC;

   -- Declare the shift register signal
   SIGNAL sr: STD_LOGIC_VECTOR((NUM_STAGES-1) DOWNTO 0);

begin

   process (clk)
   begin
      if (rising_edge(clk)) then

         if (enable = '1') then

         -- Shift data by one stage; data from last stage is lost
         sr((NUM_STAGES-1) downto 1) <= sr((NUM_STAGES-2) downto 0);

         -- Load new data into the first stage
         sr(0) <= dIn;

         end if;
      end if;
   end process;

   -- Capture the data from the last stage, before it is lost
   dOut <= sr;
end;