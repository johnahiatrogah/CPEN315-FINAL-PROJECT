-- =============================================================
-- Component  : Instruction Memory (32-bit)
-- Description: Combinational ROM holding 32 instructions (32-bit)
-- Upgraded   : 16-bit → 32-bit (PC input, instruction output, ROM)
-- Review     : PC limit raised to 0x0080 (32 words × 4 bytes).
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Instruction_Memory is
    port (
        pc          : in  std_logic_vector(31 downto 0);  -- 32-bit program counter
        instruction : out std_logic_vector(31 downto 0)   -- 32-bit fetched instruction
    );
end Instruction_Memory;

architecture Behavioral of Instruction_Memory is

    -- ROM: 32 instructions × 32 bits
    type rom_type is array (0 to 31) of std_logic_vector(31 downto 0);

    -- ---------------------------------------------------------------
    -- Sample program (32-bit MIPS-style encoding used in this design)
    -- Format per instruction depends on the control unit opcode table.
    -- Slots not yet used are NOP (all zeros).
    -- ---------------------------------------------------------------
    constant rom_data : rom_type := (
        -- 000: ADD  R1, R2, R3  (R-type, opcode=000, funct in [2:0])
        0  => "0000010010000110000000000000000",  -- placeholder encoding
        -- 001: SUB  R4, R1, R2
        1  => "0000000010000001000000000000000",
        -- 002: AND  R5, R1, R3
        2  => "0000010000000010100000000000000",
        -- 003: OR   R6, R4, R5
        3  => "0000101000010011000000000000000",
        -- 004: LW   R7, 4(R0)   (opcode=100)
        4  => "1000000000111000000000000000100",
        -- 005: SW   R7, 8(R0)   (opcode=101)
        5  => "1010000000111000000000000001000",
        -- 006: BEQ  R1, R2, +2  (opcode=110)
        6  => "1100000100000100000000000000010",
        -- 007: J    12          (opcode=111)
        7  => "1110000000000000000000000001100",
        -- 008-031: NOP
        others => x"00000000"
    );

    -- Word-aligned PC → 5-bit index (32 words)
    signal rom_addr : std_logic_vector(4 downto 0);

begin

    -- Drop 2 LSBs (byte address → word index), take 5 bits for 32 entries
    rom_addr <= pc(6 downto 2);

    -- Combinational fetch; stall/invalid if PC beyond program
    instruction <= rom_data(to_integer(unsigned(rom_addr)))
                   when unsigned(pc) < x"00000080"   -- 32 words × 4 bytes
                   else x"00000000";

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. Width change: pc and instruction are now 32 bits.
--    rom_data elements are 32-bit vectors.
-- 2. Address slicing: rom_addr takes pc[6:2] — the 5 bits above
--    the 2-bit byte offset, indexing 0..31.
-- 3. PC limit: raised from 0x0020 (32 bytes in 16-bit version)
--    to 0x0080 (128 bytes = 32 words × 4 bytes per word).
-- 4. Instruction encodings in rom_data are illustrative.
--    Replace them with your actual assembled machine code
--    before synthesis or simulation.
-- 5. The ROM is fully combinational (no clock). This is correct
--    for a single-cycle MIPS fetch stage.
-- =============================================================
