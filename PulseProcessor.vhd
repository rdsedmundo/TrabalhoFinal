LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY PulseProcessor IS
	PORT (
		stBaixo, stMedio, stAlto : IN STD_LOGIC;
		Duty 					 : OUT UNSIGNED (25 DOWNTO 0)
	);
END PulseProcessor;

ARCHITECTURE structural OF PulseProcessor IS
BEGIN

	PROCESS(stBaixo, stMedio, stAlto) IS
	BEGIN
		IF(stBaixo = '1') THEN
			Duty <= "01001100010010110100000000";
		ELSIF(stMedio = '1') THEN
			Duty <= "01111111000001111000100000";
		ELSIF(stAlto = '1') THEN
			Duty <= "11111110000011110001000000";
		ELSE
			Duty <= "00000000000000000000000000";
		END IF;
	END PROCESS;

END structural;