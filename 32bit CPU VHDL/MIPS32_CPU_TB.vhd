-- =============================================================
-- Testbench : MIPS32_CPU_TB
-- Description: Clocks the CPU for 20 cycles and observes output
--              via simulation. No I/O ports on the DUT.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MIPS32_CPU_TB is
end MIPS32_CPU_TB;

architecture Sim of MIPS32_CPU_TB is

    component MIPS32_CPU is
        port (
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    constant CLK_PERIOD : time := 10 ns;

begin

    -- DUT instantiation
    DUT : MIPS32_CPU
        port map (
            clk   => clk,
            reset => reset
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Stimulus
    process
    begin
        -- Hold reset for 2 clock cycles
        wait for CLK_PERIOD * 2;
        reset <= '0';

        -- Run for 20 instruction cycles
        wait for CLK_PERIOD * 20;

        -- Re-assert reset to verify initialisation
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';

        wait for CLK_PERIOD * 10;

        -- End simulation
        report "Simulation complete" severity note;
        wait;
    end process;

end Sim;

-- =============================================================
-- HOW TO SIMULATE (GHDL example):
--   ghdl -a Data_Memory.vhd
--   ghdl -a Instruction_Memory.vhd
--   ghdl -a Register_File.vhd
--   ghdl -a ALU.vhd
--   ghdl -a ALU_Control.vhd
--   ghdl -a Control_Unit.vhd
--   ghdl -a MIPS32_CPU.vhd
--   ghdl -a MIPS32_CPU_TB.vhd
--   ghdl -e MIPS32_CPU_TB
--   ghdl -r MIPS32_CPU_TB --vcd=wave.vcd
--   gtkwave wave.vcd
-- =============================================================
