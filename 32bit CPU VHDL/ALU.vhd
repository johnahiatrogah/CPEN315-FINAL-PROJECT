-- =============================================================
-- Component  : ALU (32-bit)
-- Description: Arithmetic Logic Unit with 5 operations
-- Upgraded   : 16-bit → 32-bit operands and result
-- Review     : SLT uses signed comparison (MIPS convention).
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
    port (
        a           : in  std_logic_vector(31 downto 0);  -- operand A
        b           : in  std_logic_vector(31 downto 0);  -- operand B
        alu_control : in  std_logic_vector(2 downto 0);   -- operation select
        alu_result  : out std_logic_vector(31 downto 0);  -- result
        zero        : out std_logic                        -- zero flag
    );
end ALU;

architecture Behavioral of ALU is

    signal result : std_logic_vector(31 downto 0);

begin

    -- ---------------------------------------------------------------
    -- ALU operation table
    --   000 → ADD
    --   001 → SUB
    --   010 → AND
    --   011 → OR
    --   100 → SLT  (set on less than, signed)
    --   others → ADD (safe default)
    -- ---------------------------------------------------------------
    process(a, b, alu_control)
    begin
        case alu_control is
            when "000" =>   -- ADD
                result <= std_logic_vector(
                    signed(a) + signed(b));

            when "001" =>   -- SUB
                result <= std_logic_vector(
                    signed(a) - signed(b));

            when "010" =>   -- AND
                result <= a and b;

            when "011" =>   -- OR
                result <= a or b;

            when "100" =>   -- SLT  (signed less-than)
                if signed(a) < signed(b) then
                    result <= x"00000001";
                else
                    result <= x"00000000";
                end if;

            when others =>  -- default: ADD
                result <= std_logic_vector(
                    signed(a) + signed(b));
        end case;
    end process;

    -- Zero flag: asserted when result is all zeros
    zero       <= '1' when result = x"00000000" else '0';
    alu_result <= result;

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. Width change: a, b, alu_result are 32-bit; zero flag
--    comparison literal updated to x"00000000".
-- 2. SLT uses signed() cast — correct for MIPS 'slt' instruction.
--    Use unsigned() cast if you need 'sltu' (unsigned less-than).
-- 3. ADD/SUB use signed() arithmetic which wraps on overflow
--    (no overflow exception in this design). Add an overflow
--    output port and detect with XOR of carry bits if needed.
-- 4. The process sensitivity list includes a, b, alu_control —
--    fully combinational, no clock needed.
-- 5. 'others' default falls through to ADD, preventing latches
--    in synthesis.
-- =============================================================
