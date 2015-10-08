LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.numeric_std.ALL;

ENTITY FPGA_ADCMAX1111 IS 
  PORT(-- Control Interface
       StartRead: IN STD_LOGIC;    -- Solicita iniciar a conversão (Borda de Subida)
       Done:      OUT STD_LOGIC;   -- Informa que a conversão terminou (Borda de Subida)
       Data:      OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Valor lido do conversor
       SysClk:    IN STD_LOGIC;    -- Clock do sistema
       
       -- SPI Interface
       ADC_CLK:   OUT STD_LOGIC;   -- D12 <-> PINO 15
       ADC_CSN:   OUT STD_LOGIC;   -- C12 <-> PINO 14
       ADC_DIN:   OUT STD_LOGIC;   -- B12 <-> PINO 13
       ADC_DOUT:  IN  STD_LOGIC;   -- A11 <-> PINO 11
       ADC_SSTRB: OUT STD_LOGIC;   -- A12 <-> PINO 12
       ADC_SHDN:  OUT STD_LOGIC    -- B11 <-> PINO 6
       );
       
END ENTITY FPGA_ADCMAX1111;

-- Byte de controle
-- START SEL2  SEL1 SEL0  UNI/!BIP SGL/!DIF'  PD1 PD0
-- Start: O primeiro 1 depois de !CS ficar baixo define o inicio do byte de controle
-- SELx : Seleciona o canal
-- UNI/!BIP: 1 Unipolar, 0 bipolar
-- SGL/!DIF: 1 Single ended, 0 diferencial
-- PD1: 1 completamente operacional, 0 power-down
-- PD0: 1 external clock, 0 internal clock

-- SPI Mode: CPOL = 0 e CPHA = 0
-- Frequência de 50kHz a 500kHz
-- RISING EDGE clocks a bit from DIN
-- FALLING EDGE clocks a bit from DOUT

-- Byte de Controle
-- Coloca o bit, espera o tempo em baixo, e sobe o clock


ARCHITECTURE ARCH_FPGA_ADCMAX1111 OF FPGA_ADCMAX1111 IS 
  TYPE STATE_TYPE IS (idle, start, transfering, finished);
  TYPE WAIT_TYPE IS (stopped, running);

  SIGNAL estado: STATE_TYPE := idle;
  CONSTANT config: STD_LOGIC_VECTOR(0 TO 29) := "011001111000000000000000000000";
  SIGNAL bitConfig: STD_LOGIC;
  SIGNAL nivelStrobe: STD_LOGIC;
  SIGNAL nivelCS: STD_LOGIC;

  SIGNAL clkReset: STD_LOGIC;
  SIGNAL clkEnable: STD_LOGIC;
  SIGNAL inClock: STD_LOGIC;  
  
  SIGNAL indice : INTEGER := 0;
  
  CONSTANT NUMERO_PULSOS_COMUNICACAO : INTEGER := 24;
  CONSTANT INDICE_PRIMEIRO_BIT_DADO : INTEGER := 12;
  
  COMPONENT CLOCK_GENERATOR PORT(
    SysClk: IN STD_LOGIC;
    Reset:  IN STD_LOGIC;
    Enable: IN STD_LOGIC;
    Clock:  OUT STD_LOGIC
  ); END COMPONENT;
  
BEGIN

  PROCESS(SysClk, StartRead, inClock, estado) 
    VARIABLE bitsLidos : STD_LOGIC_VECTOR(0 TO 24) := (OTHERS => '0');
    VARIABLE bitsDados: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    VARIABLE nivelDone : STD_LOGIC := '0';
  BEGIN
  
    if (SysClk'event AND SysClk = '1') then
  
      -- NÃO ESTÁ FAZENDO NADA E TAMBÉM NÃO SOLICITOU O INÍCIO DA CONVERSÃO -
      if (estado = idle AND StartRead = '1') then
        estado <= idle;
        clkReset <= '1';
        clkEnable <= '0';
        nivelCS <= '1';
        nivelStrobe <= '1';
        nivelDone := '1';
        -- Mais para o menos significativo
        bitsDados(7) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 0);
        bitsDados(6) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 1);
        bitsDados(5) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 2);
        bitsDados(4) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 3);
        bitsDados(3) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 4);
        bitsDados(2) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 5);
        bitsDados(1) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 6);
        bitsDados(0) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 7);
      elsif (estado = idle AND StartRead = '0') then
        -- Configura os valores iniciais
        clkReset <= '1';
        clkEnable <= '1';
        nivelCS <= '0';
        nivelStrobe <= '0';
        nivelDone := '0';
        bitsDados := (OTHERS => '0');
        -- Troca para o estado START
        estado <= start;

      -- INICIO DA CONVERSÃO ACEITA, MAS NÃO LIBEROU O START READ AINDA
      elsif (estado = start AND StartRead = '0') then
        estado <= start;
        clkReset <= '1';
        clkEnable <= '1';
        nivelCS <= '0';
        nivelStrobe <= '0';
        nivelDone := '0';
        bitsDados := (OTHERS => '0');
        
      -- INICIO DA CONVERSÃO E SOLTOU O STARTREAD
      elsif (estado = start AND StartRead = '1') then
        -- Pára de resetar o clock
        clkReset <= '0';
        clkEnable <= '1';
        nivelCS <= '0';
        nivelStrobe <= '0';
        bitsDados := (OTHERS => '0');
        -- Troca para o estado TRANSFERING
        estado <= transfering;
        nivelDone := '0';
        
      -- ESTÁ TRANSFERINDO OS DADOS
      elsif (estado = transfering) then
        clkReset <= '0';
        clkEnable <= '1';
        nivelCS <= '0';
        nivelStrobe <= '0';
        nivelDone := '0';
        bitsDados := (OTHERS => '0');
        
        -- CONTINUA FAZENDO O QUE JÁ ESTAVA FAZENDO ATÉ CHEGAR NO INDICE = 24
        if (indice = NUMERO_PULSOS_COMUNICACAO) then
          estado <= finished;
        else
          estado <= transfering;
        end if;
        
      else

        -- Finalizou
        -- Mais para o menos significativo
        bitsDados(7) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 0);
        bitsDados(6) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 1);
        bitsDados(5) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 2);
        bitsDados(4) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 3);
        bitsDados(3) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 4);
        bitsDados(2) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 5);
        bitsDados(1) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 6);
        bitsDados(0) := bitsLidos(INDICE_PRIMEIRO_BIT_DADO + 7);
        -- Vai para IDLE
        estado <= idle;
        nivelDone := '1';
        
        clkReset <= '1';
        clkEnable <= '0';
        nivelCS <= '1';
        nivelStrobe <= '1';
      end if;
    end if;
    
    -- Realiza a leitura do dado
    if (inClock'event AND inClock='1')  then
      bitsLidos(indice) := ADC_DOUT;
    end if;
    
    -- Realizo a configuração dos bits
    if (inClock'event AND inClock='0') then
      bitConfig <= config(indice);
    end if;
    
    -- Controla o índice
    if (estado = transfering) then
      if (inClock'event AND inClock = '0') then
        indice <= indice + 1;
      end if;
    else
      indice <= 0;
    end if;
    
    -- Assinalamento constante
    Data <= bitsDados;
    Done <= nivelDone;
  END PROCESS;
  
  -- Assinalamentos
  ADC_SHDN <= '1';            -- SHUTDOWN' = Nunca desliga o chip
  ADC_CLK <= inClock;
  ADC_DIN <= bitConfig;
  ADC_SSTRB <= nivelStrobe;
  ADC_CSN <= nivelCS;
  
  
  -- Clock para o MAX1111 (50KHz)
  clk1 : CLOCK_GENERATOR PORT MAP(SysClk, clkReset, clkEnable, inClock);

END ARCHITECTURE ARCH_FPGA_ADCMAX1111;