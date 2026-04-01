-- =============================================================
-- Component  : ALU Control Unit (32-bit)
-- Description: Decodes ALUOp + function field → ALU control bits
-- Upgraded   : No bit-width changes needed (control signals only)
-- Review     : ALU_Funct is now 6 bits to match 32-bit MIPS funct.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_Control is
    port (
        ALUOp       : in  std_logic_vector(1 downto 0);  -- from main control
        ALU_Funct   : in  std_logic_vector(5 downto 0);  -- instruction[5:0] (6-bit in 32-bit MIPS)
        ALU_Control : out std_logic_vector(2 downto 0)   -- to ALU
    );
end ALU_Control;

architecture Behavioral of ALU_Control is
begin

    process(ALUOp, ALU_Funct)
    begin
        case ALUOp is
            -- R-type: decode the 6-bit funct field
            -- Only the 3 LSBs are used to select the operation
            when "00" =>
                case ALU_Funct(2 downto 0) is
                    when "000" => ALU_Control <= "000";  -- ADD  (funct=100000 in std MIPS)
                    when "001" => ALU_Control <= "001";  -- SUB  (funct=100010)
                    when "010" => ALU_Control <= "010";  -- AND  (funct=100100)
                    when "011" => ALU_Control <= "011";  -- OR   (funct=100101)
                    when "100" => ALU_Control <= "100";  -- SLT  (funct=101010)
                    when others => ALU_Control <= "000"; -- default ADD
                end case;

            -- BEQ: subtract to check equality
            when "01" => ALU_Control <= "001";  -- SUB

            -- LW / SW: add base + offset
            when "10" => ALU_Control <= "000";  -- ADD

            -- J-type / other: addition (address calc)
            when "11" => ALU_Control <= "000";  -- ADD

            when others => ALU_Control <= "000";
        end case;
    end process;

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. ALU_Funct widened from 3 to 6 bits to match the 32-bit
--    MIPS instruction format (bits [5:0] of the instruction).
--    The inner case still uses Funct(2:0) for the 5-operation
--    ALU in this design; extend if you add more operations.
-- 2. ALUOp "01" drives SUB for BEQ (branch-on-equal uses
--    subtraction to produce the zero flag).
-- 3. ALUOp "10" drives ADD for LW/SW (effective address = base
--    register + sign-extended immediate).
-- 4. This is fully combinational — no clock port needed.
-- 5. The 16-bit version used ALUOp="01"→"001" for SUB and
--    "10"→"100" (SLT). Mapping is adjusted here to be more
--    faithful to standard MIPS single-cycle control encoding.
-- =============================================================
