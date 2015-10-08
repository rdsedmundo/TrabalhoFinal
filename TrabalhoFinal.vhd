LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY TrabalhoFinal IS
	PORT(		
		sysClock 	: IN STD_LOGIC;  -- Clock de 66.66MHz
		LED_Baixo 	: OUT STD_LOGIC; -- Indica que a intensidade da temperatura está baixa
		LED_Medio 	: OUT STD_LOGIC; -- Indica que a intensidade da temperatura está média
		LED_Alto  	: OUT STD_LOGIC; -- Indica que a intensidade da temperatura está alta	
		
		Botao_Baixo : IN STD_LOGIC;  -- Botão para forçar o Cooler à girar em TENSÂO baixa
		Botao_Medio	: IN STD_LOGIC;	 -- Botão para forçar o Cooler à girar em TENSÂO média
		Botao_Alto 	: IN STD_LOGIC;  -- Botão para forçar o Cooler à girar em TENSÂO alta
		
		Pulso       : OUT STD_LOGIC := '0';	-- Sinal que representa a TENSÂO sob a qual o Cooler deve girar
		
		-- MAX1111 - SPI Interface
		ADC_CLK:   OUT STD_LOGIC;    -- D12 <-> PINO 15
		ADC_CSN:   OUT STD_LOGIC;    -- C12 <-> PINO 14
		ADC_DIN:   OUT STD_LOGIC;    -- B12 <-> PINO 13
		ADC_DOUT:  IN  STD_LOGIC;    -- A11 <-> PINO 11
		ADC_SSTRB: OUT STD_LOGIC;    -- A12 <-> PINO 12
		ADC_SHDN:  OUT STD_LOGIC     -- B11 <-> PINO 6	
		);	
END TrabalhoFinal;

ARCHITECTURE structural OF TrabalhoFinal IS
	
	COMPONENT cControle IS
		PORT(
			Temperatura : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Indica o binário equivalente da temperatura atual
			Pronto		: IN STD_LOGIC;					   -- Indica que uma nova conversão de dados foi feita
			sysClock    : IN STD_LOGIC; 				   -- Clock de 66.66MHz
			LED_Baixo 	: OUT STD_LOGIC; 				   -- Indica que a intensidade da temperatura está baixa
			LED_Medio 	: OUT STD_LOGIC; 				   -- Indica que a intensidade da temperatura está média
			LED_Alto  	: OUT STD_LOGIC); 				   -- Indica que a intensidade da temperatura está alta		
	END COMPONENT;
	
	COMPONENT cMAX_1111 IS
	   PORT(
		   StartRead: IN STD_LOGIC;    -- Solicita iniciar a conversão (Borda de Subida)
		   Done:      OUT STD_LOGIC;   -- Informa que a conversão terminou (Borda de Subida)
		   Data:      OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Valor lido do conversor
		   SysClk:    IN STD_LOGIC;    -- Clock do sistema
		   
		   -- MAX1111 - SPI Interface
		   ADC_CLK:   OUT STD_LOGIC;   -- D12 <-> PINO 15
		   ADC_CSN:   OUT STD_LOGIC;   -- C12 <-> PINO 14
		   ADC_DIN:   OUT STD_LOGIC;   -- B12 <-> PINO 13
		   ADC_DOUT:  IN  STD_LOGIC;   -- A11 <-> PINO 11
		   ADC_SSTRB: OUT STD_LOGIC;   -- A12 <-> PINO 12
		   ADC_SHDN:  OUT STD_LOGIC);  -- B11 <-> PINO 6
	END COMPONENT;
	
	COMPONENT cPWM IS
		PORT(
		 Periodo: IN UNSIGNED (26 DOWNTO 0);	-- Indica o período total do pulso que será gerado
		 Duty_Cicle: IN UNSIGNED (25 DOWNTO 0); -- Indica o período total em que o pulso ficará em ALTO
		 sysClock: IN STD_LOGIC; 				-- Clock de 66.66MHz
		 Saida: OUT STD_LOGIC);					-- Sinal que representa a TENSÂO sob a qual o Cooler deve girar
	END COMPONENT;
	
	COMPONENT cPulse IS
		PORT (
		 stBaixo, stMedio, stAlto : IN STD_LOGIC;
		 Duty 					  : OUT UNSIGNED (25 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT cConversor IS
		PORT(
		 xDados : IN STD_LOGIC_VECTOR  (7 DOWNTO 0);
		 xTemp  : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT;
	
	FOR ALL: cControle  USE ENTITY work.ControleMotor(structural);
	FOR ALL: cMAX_1111  USE ENTITY work.FPGA_ADCMAX1111(ARCH_FPGA_ADCMAX1111);
	FOR ALL: cPWM       USE ENTITY work.PWM(structural);
	FOR ALL: cPulse     USE ENTITY work.PulseProcessor(structural);
	
	SIGNAL Temperatura : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"; -- Sinal que recebe o valor da temperatura atual
	
	SIGNAL Done        : STD_LOGIC := '0'; -- Sinal que indica que a conversão foi finalizada
	
	SIGNAL Periodo     : UNSIGNED (26 DOWNTO 0) := "000011001001011010101000000"; -- Sinal com 6.66MHz de Frequência
	SIGNAL DutyCicle   : UNSIGNED (25 DOWNTO 0) := "00001100100101101010100000";  -- 50% de 6.66MHz
	
	SIGNAL StartRead   : STD_LOGIC; -- Solicita ao MAX1111 uma nova conversão de valores
	
	SIGNAL sLED_Baixo, sLED_Medio, sLED_Alto : STD_LOGIC := '0'; -- Sinais que armazenam a intensidade de temperatura calculada pelo controle
	
	SIGNAL Periodo_Saida   : UNSIGNED (26 DOWNTO 0) := "011111110000011110001000000"; -- Sinal com 66.66MHz de Frequência
	SIGNAL DutyCicle_Saida : UNSIGNED (25 DOWNTO 0) := "00000000000000000000000000";  -- Sinal para determinar o tempo que o Cooler deve girar à cada pulso
	
BEGIN

	LED_Baixo	  <= NOT(sLED_Baixo);
	LED_Medio 	  <= NOT(sLED_Medio); 
	LED_Alto  	  <= NOT(sLED_Alto);
	
	Periodo_Saida <= Periodo_Saida;
	Periodo       <= Periodo;
	DutyCicle     <= DutyCicle;
 
	m1: cPWM 	   PORT MAP (Periodo,DutyCicle,sysClock,StartRead);  
	m2: cMAX_1111  PORT MAP (StartRead,Done,Temperatura,sysClock,ADC_CLK,ADC_CSN,ADC_DIN,ADC_DOUT,ADC_SSTRB,ADC_SHDN);
	m3: cControle  PORT MAP (Temperatura,Done,sysClock,sLED_Baixo,sLED_Medio,sLED_Alto);
	m4: cPulse     PORT MAP (((sLED_Baixo) OR (NOT(Botao_Baixo))),((sLED_Medio) OR (NOT(Botao_Medio))),((sLED_Alto) OR (NOT(Botao_Alto))),DutyCicle_Saida);
	m5: cPWM  	   PORT MAP (Periodo_Saida,DutyCicle_Saida,sysClock,Pulso); 
	
END structural;