----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    07:44:38 02/17/2022 
-- Design Name: 
-- Module Name:    MCD_VHDL_Wang - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MCD_VHDL_Wang is
    Port (
        -- 8 MHz clock
		CLK : in STD_LOGIC;

		BTNRESET : in  STD_LOGIC;
        SUPRESET : in  STD_LOGIC;

        -- use A16-17 to decode, rest unused
        A2 : in STD_LOGIC_VECTOR(23 downto 18);
        A : in STD_LOGIC_VECTOR(17 downto 16); 

        AS : in STD_LOGIC;
        UDS : in STD_LOGIC;
        LDS : in STD_LOGIC;
        RW : in STD_LOGIC;

        FCS : in  STD_LOGIC_VECTOR(2 downto 0);

        TPS : inout  STD_LOGIC_VECTOR(7 downto 0);

        DTACK : inout STD_LOGIC;

        RESET : out STD_LOGIC;

        BERR : out STD_LOGIC;

        OE : out STD_LOGIC;
        WE : out STD_LOGIC;

        URAMCS : out STD_LOGIC;
        LRAMCS : out STD_LOGIC;

        UROMCS : out STD_LOGIC;
        LROMCS : out STD_LOGIC;

        DUARTCS : out STD_LOGIC;

        LEDS : out  STD_LOGIC_VECTOR(7 downto 0)
    );
end MCD_VHDL_Wang;

architecture Behavioral of MCD_VHDL_Wang is

    signal clock : std_logic_vector(27 downto 0);

begin

    -- process to divide clock
	DivideClock : process(CLK)
    begin
        if (rising_edge(CLK)) then
            clock <= clock + "1";
        end if;
    end process;
    
    -- A17 and A16, ROM 00, RAM 01, DUART 10
    -- select UROM when ROM selected and AS active (OR gate because active low)
    UROMCS <= UDS when (A = "00" and AS = '0') else '1';
    LROMCS <= LDS when (A = "00" and AS = '0') else '1';

    URAMCS <= UDS when (A = "01" and AS = '0') else '1';
    LRAMCS <= LDS when (A = "01" and AS = '0') else '1';

    DUARTCS <= LDS when (A = "10" and AS = '0') else '1';

    -- when DUART selected, set DTACK to Z (high impedance, floating), so DUART DTACK controls
    -- otherwise set to AS (will be driven high when AS is not used, high)
    DTACK <= 'Z' when A = "10" else AS;


    -- set OE (read) and WE (write) according to RW
    OE <= not(RW);
    WE <= RW;

    
    -- RESET output goes low when etiher SUPRESET or BTNRESET are low
    -- all active low
    RESET <= (SUPRESET and BTNRESET);


    -- blink an LED dividing clock vector (should be around every 1s)
    LEDS(0) <= clock(22);

    LEDS(3) <= (SUPRESET and BTNRESET);
    
    LEDS(5) <= FCS(0);
    LEDS(6) <= FCS(1);
    LEDS(7) <= FCS(2);
    

    -- test points
	TPS(0) <= AS;
	TPS(1) <= DTACK;
    TPS(2) <= RW;
    TPS(3) <= (SUPRESET and BTNRESET);

    TPS(4) <= UDS;
    TPS(5) <= LDS;
    TPS(6) <= A(17);
    TPS(7) <= A(16);
    --TPS(7) <= CLK;


    -- drive BERR high
    BERR <= '1';
	 
end Behavioral;