LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY CLOCK_GENERATOR IS
  PORT(SysClk: IN STD_LOGIC;
       Reset:  IN STD_LOGIC;
       Enable: IN STD_LOGIC;
       Clock:  OUT STD_LOGIC);
END ENTITY CLOCK_GENERATOR;

ARCHITECTURE ARCH_CLOCK_GENERATOR OF CLOCK_GENERATOR IS

  CONSTANT CLK_FREQ : INTEGER := 66660000;  -- Sys Clock 66.66MHz
  CONSTANT BLINK_SEG: INTEGER := 50000;     -- ADC Clock 50 KHz
  CONSTANT COUNTER_MAX: INTEGER := CLK_FREQ/BLINK_SEG/2 -1;
  SIGNAL counter: UNSIGNED(27 DOWNTO 0);
  SIGNAL inClock: STD_LOGIC;

BEGIN

  PROCESS(SysClk, Reset, Enable) BEGIN
    IF (Reset = '1') THEN
      -- Se o Reset = 1, zera o valor do contador, independente
      -- do estado dele
      counter <= (OTHERS => '0');
      inClock <= '0';
    ELSIF (Enable = '1' AND Reset = '0') THEN
      IF (RISING_EDGE(SysClk)) THEN
        IF (counter = COUNTER_MAX) THEN
          counter <= (OTHERS => '0');
          inClock <= NOT inClock;
        ELSE
          counter <= counter + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
  Clock <= inClock;
   
END ARCHITECTURE ARCH_CLOCK_GENERATOR;