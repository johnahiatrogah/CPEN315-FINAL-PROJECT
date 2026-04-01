-- =============================================================
-- Component  : CPU Control Unit (32-bit)
-- Description: Decodes 6-bit opcode → all datapath control signals
-- Upgraded   : opcode widened 3→6 bits; reg_dst/mem_to_reg stay
--              2-bit to support write-back MUX selection.
-- Review     : Signal widths and opcode encodings updated below.
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Control_Unit is
    port (
        opcode      : in  std_logic_vector(5 downto 0);  -- instruction[31:26]
        reset       : in  std_logic;

        -- Destination / write-back
        reg_dst     : out std_logic_vector(1 downto 0);  -- 00=rt, 01=rd, 10=31(JAL)
        mem_to_reg  : out std_logic_vector(1 downto 0);  -- 00=ALU, 01=Mem, 10=PC+4

        -- ALU control
        alu_op      : out std_logic_vector(1 downto 0);

        -- Branch / jump
        jump        : out std_logic;
        branch      : out std_logic;

        -- Memory
        mem_read    : out std_logic;
        mem_write   : out std_logic;

        -- Operand source
        alu_src     : out std_logic;   -- 0=register B, 1=sign-extended immediate
        sign_or_zero: out std_logic;   -- 1=sign-extend, 0=zero-extend

        -- Register write enable
        reg_write   : out std_logic
    );
end Control_Unit;

architecture Behavioral of Control_Unit is
begin

    process(reset, opcode)
    begin
        if reset = '1' then
            -- Safe default: all signals de-asserted
            reg_dst      <= "00";
            mem_to_reg   <= "00";
            alu_op       <= "00";
            jump         <= '0';
            branch       <= '0';
            mem_read     <= '0';
            mem_write    <= '0';
            alu_src      <= '0';
            sign_or_zero <= '1';
            reg_write    <= '0';

        else
            case opcode is

                -- -----------------------------------------------
                -- R-type  (opcode = 000000)
                -- -----------------------------------------------
                when "000000" =>
                    reg_dst      <= "01";  -- destination = rd
                    mem_to_reg   <= "00";  -- write-back from ALU
                    alu_op       <= "00";  -- ALU control decodes funct
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '0';   -- second operand = register
                    sign_or_zero <= '1';
                    reg_write    <= '1';

                -- -----------------------------------------------
                -- ADDI  (opcode = 001000)
                -- -----------------------------------------------
                when "001000" =>
                    reg_dst      <= "00";  -- destination = rt
                    mem_to_reg   <= "00";
                    alu_op       <= "11";  -- ALU: ADD
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '1';   -- second operand = immediate
                    sign_or_zero <= '1';   -- sign-extend immediate
                    reg_write    <= '1';

                -- -----------------------------------------------
                -- LW    (opcode = 100011)
                -- -----------------------------------------------
                when "100011" =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "01";  -- write-back from memory
                    alu_op       <= "10";  -- ALU: ADD (address calc)
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '1';
                    mem_write    <= '0';
                    alu_src      <= '1';
                    sign_or_zero <= '1';
                    reg_write    <= '1';

                -- -----------------------------------------------
                -- SW    (opcode = 101011)
                -- -----------------------------------------------
                when "101011" =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "00";
                    alu_op       <= "10";  -- ALU: ADD (address calc)
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '1';
                    alu_src      <= '1';
                    sign_or_zero <= '1';
                    reg_write    <= '0';   -- no register write on SW

                -- -----------------------------------------------
                -- BEQ   (opcode = 000100)
                -- -----------------------------------------------
                when "000100" =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "00";
                    alu_op       <= "01";  -- ALU: SUB (for zero flag)
                    jump         <= '0';
                    branch       <= '1';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '0';
                    sign_or_zero <= '1';
                    reg_write    <= '0';

                -- -----------------------------------------------
                -- J     (opcode = 000010)
                -- -----------------------------------------------
                when "000010" =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "00";
                    alu_op       <= "00";
                    jump         <= '1';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '0';
                    sign_or_zero <= '1';
                    reg_write    <= '0';

                -- -----------------------------------------------
                -- ANDI  (opcode = 001100)  — zero-extend immediate
                -- -----------------------------------------------
                when "001100" =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "00";
                    alu_op       <= "00";  -- ALU control will use AND
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '1';
                    sign_or_zero <= '0';   -- zero-extend for logical imm
                    reg_write    <= '1';

                -- -----------------------------------------------
                -- Default: safe NOP
                -- -----------------------------------------------
                when others =>
                    reg_dst      <= "00";
                    mem_to_reg   <= "00";
                    alu_op       <= "00";
                    jump         <= '0';
                    branch       <= '0';
                    mem_read     <= '0';
                    mem_write    <= '0';
                    alu_src      <= '0';
                    sign_or_zero <= '1';
                    reg_write    <= '0';

            end case;
        end if;
    end process;

end Behavioral;

-- =============================================================
-- REVIEW NOTES
-- 1. opcode widened from 3 to 6 bits — matches the 32-bit MIPS
--    instruction format where bits [31:26] carry the opcode.
--    The 3-bit design forced custom encodings; this version uses
--    standard MIPS opcodes for LW, SW, BEQ, J, ADDI, ANDI.
-- 2. Standard MIPS opcodes used:
--       R-type  = 000000
--       ADDI    = 001000
--       LW      = 100011
--       SW      = 101011
--       BEQ     = 000100
--       J       = 000010
--       ANDI    = 001100
-- 3. reg_dst and mem_to_reg remain 2-bit to allow a third MUX
--    input (e.g. JAL writes PC+4 to R31).
-- 4. sign_or_zero added to distinguish sign-extend (arithmetic
--    immediates) from zero-extend (logical immediates like ANDI).
-- 5. reg_write is deasserted for SW, BEQ, and J — instructions
--    that do not produce a register result.
-- =============================================================
