-- =============================================================
-- Component  : Data Memory (32-bit)
-- Description: Synchronous read/write RAM with 256 x 32-bit words
-- Upgraded   : 16-bit → 32-bit (all ports, arrays, and init values)
-- Review     : Addresses are word-aligned (byte addr >> 2).
--              Read is registered (clocked), consistent with
--              single-cycle MIPS where mem_read is asserted same cycle.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Data_Memory is
    port (
        clk             : in  std_logic;
        mem_access_addr : in  std_logic_vector(31 downto 0);   -- 32-bit address
        mem_write_data  : in  std_logic_vector(31 downto 0);   -- 32-bit write data
        mem_write_en    : in  std_logic;
        mem_read        : in  std_logic;
        mem_read_data   : out std_logic_vector(31 downto 0)    -- 32-bit read data
    );
end Data_Memory;

architecture Behavioral of Data_Memory is

    -- 256 words × 32 bits = 1 KB data memory
    type data_mem_type is array (0 to 255) of std_logic_vector(31 downto 0);

    signal RAM : data_mem_type := (others => x"00000000");

    -- Word-align: drop the 2 LSBs for byte addressing
    signal ram_addr : std_logic_vector(7 downto 0);

begin

    -- Word-aligned address: bits [9:2] index into 256-word array
    ram_addr <= mem_access_addr(9 downto 2);

    process(clk)
    begin
        if rising_edge(clk) then
            -- Synchronous write
            if mem_write_en = '1' then
                RAM(to_integer(unsigned(ram_addr))) <= mem_write_data;
            end if;

            -- Synchronous read
            if mem_read = '1' then
                mem_read_data <= RAM(to_integer(unsigned(ram_addr)));
            else
                mem_read_data <= x"00000000";
            end if;
        end if;
    end process;

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. Width change: all ports and the array element width are now
--    32 bits. The init literal uses x"00000000" (8 hex digits).
-- 2. Address indexing: ram_addr now slices [9:2] from the 32-bit
--    address, preserving word-alignment for a 256-word memory.
--    In the 16-bit version [7:0] was used — adjust slice bounds
--    if you extend the memory beyond 256 words.
-- 3. Read latency: read is still synchronous (registered on clk
--    rising edge). For an asynchronous read (combinational),
--    move the read assignment outside the clocked process.
-- 4. No out-of-range protection: to_integer(unsigned(ram_addr))
--    is clamped to 0-255 by the 8-bit slice, so no overflow risk.
-- =============================================================
