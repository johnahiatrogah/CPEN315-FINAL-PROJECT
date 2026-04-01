-- =============================================================
-- Component  : Register File (32-bit)
-- Description: 32 general-purpose 32-bit registers (MIPS R0..R31)
-- Upgraded   : 8 registers / 16-bit → 32 registers / 32-bit
-- Review     : R0 is hardwired to 0x00000000 (MIPS convention).
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Register_File is
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        reg_write_en    : in  std_logic;
        reg_write_dest  : in  std_logic_vector(4 downto 0);   -- 5-bit: 0..31
        reg_write_data  : in  std_logic_vector(31 downto 0);  -- 32-bit
        reg_read_addr_1 : in  std_logic_vector(4 downto 0);
        reg_read_addr_2 : in  std_logic_vector(4 downto 0);
        reg_read_data_1 : out std_logic_vector(31 downto 0);
        reg_read_data_2 : out std_logic_vector(31 downto 0)
    );
end Register_File;

architecture Behavioral of Register_File is

    type reg_file_type is array (0 to 31) of std_logic_vector(31 downto 0);

    signal registers : reg_file_type := (others => x"00000000");

begin

    -- ---------------------------------------------------------------
    -- Synchronous write + reset
    -- ---------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            -- Load test values into R1..R8; rest cleared
            registers(0)  <= x"00000000";  -- R0 hardwired 0
            registers(1)  <= x"00000001";
            registers(2)  <= x"00000002";
            registers(3)  <= x"00000003";
            registers(4)  <= x"00000004";
            registers(5)  <= x"00000005";
            registers(6)  <= x"00000006";
            registers(7)  <= x"00000007";
            registers(8)  <= x"00000008";
            -- R9..R31 default to 0
            registers(9  to 31) <= (others => x"00000000");

        elsif rising_edge(clk) then
            -- Write-back: never overwrite R0
            if reg_write_en = '1' and
               reg_write_dest /= "00000" then
                registers(to_integer(unsigned(reg_write_dest))) <= reg_write_data;
            end if;
        end if;
    end process;

    -- ---------------------------------------------------------------
    -- Asynchronous (combinational) reads — standard MIPS convention
    -- R0 always reads as zero regardless of stored value
    -- ---------------------------------------------------------------
    reg_read_data_1 <= x"00000000" when reg_read_addr_1 = "00000"
                       else registers(to_integer(unsigned(reg_read_addr_1)));

    reg_read_data_2 <= x"00000000" when reg_read_addr_2 = "00000"
                       else registers(to_integer(unsigned(reg_read_addr_2)));

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. Width change: all data ports are 32-bit; address ports are
--    5-bit (to select among 32 registers vs 3-bit for 8 regs).
-- 2. Register count: array expanded from 8 to 32 elements.
-- 3. R0 write-guard: the write process checks dest /= "00000"
--    before writing, enforcing the MIPS R0=0 convention.
-- 4. Read style: reads are asynchronous (concurrent signal
--    assignments outside the clocked process). This is the
--    standard single-cycle MIPS approach and avoids a read-after-
--    write hazard within the same cycle.
-- 5. Reset initialises R1..R8 with test values for simulation;
--    synthesise with all zeros if no preload is needed.
-- 6. Range aggregate (registers(9 to 31) <= ...) is supported
--    by IEEE-1076-2008; use individual assignments for older tools.
-- =============================================================
