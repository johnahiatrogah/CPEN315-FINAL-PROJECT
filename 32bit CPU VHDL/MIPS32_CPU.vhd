-- =============================================================
-- Component  : MIPS32 CPU — Top-Level
-- Description: Single-cycle 32-bit MIPS processor
--              Instantiates and connects all sub-components.
-- Upgraded   : 16-bit → 32-bit throughout
-- =============================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MIPS32_CPU is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end MIPS32_CPU;

architecture Structural of MIPS32_CPU is

    -- -------------------------------------------------------
    -- Component declarations
    -- -------------------------------------------------------

    component Instruction_Memory is
        port (
            pc          : in  std_logic_vector(31 downto 0);
            instruction : out std_logic_vector(31 downto 0)
        );
    end component;

    component Control_Unit is
        port (
            opcode       : in  std_logic_vector(5 downto 0);
            reset        : in  std_logic;
            reg_dst      : out std_logic_vector(1 downto 0);
            mem_to_reg   : out std_logic_vector(1 downto 0);
            alu_op       : out std_logic_vector(1 downto 0);
            jump         : out std_logic;
            branch       : out std_logic;
            mem_read     : out std_logic;
            mem_write    : out std_logic;
            alu_src      : out std_logic;
            sign_or_zero : out std_logic;
            reg_write    : out std_logic
        );
    end component;

    component Register_File is
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            reg_write_en    : in  std_logic;
            reg_write_dest  : in  std_logic_vector(4 downto 0);
            reg_write_data  : in  std_logic_vector(31 downto 0);
            reg_read_addr_1 : in  std_logic_vector(4 downto 0);
            reg_read_addr_2 : in  std_logic_vector(4 downto 0);
            reg_read_data_1 : out std_logic_vector(31 downto 0);
            reg_read_data_2 : out std_logic_vector(31 downto 0)
        );
    end component;

    component ALU_Control is
        port (
            ALUOp       : in  std_logic_vector(1 downto 0);
            ALU_Funct   : in  std_logic_vector(5 downto 0);
            ALU_Control : out std_logic_vector(2 downto 0)
        );
    end component;

    component ALU is
        port (
            a           : in  std_logic_vector(31 downto 0);
            b           : in  std_logic_vector(31 downto 0);
            alu_control : in  std_logic_vector(2 downto 0);
            alu_result  : out std_logic_vector(31 downto 0);
            zero        : out std_logic
        );
    end component;

    component Data_Memory is
        port (
            clk             : in  std_logic;
            mem_access_addr : in  std_logic_vector(31 downto 0);
            mem_write_data  : in  std_logic_vector(31 downto 0);
            mem_write_en    : in  std_logic;
            mem_read        : in  std_logic;
            mem_read_data   : out std_logic_vector(31 downto 0)
        );
    end component;

    -- -------------------------------------------------------
    -- Internal signals
    -- -------------------------------------------------------

    -- Program Counter
    signal pc_current    : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_next       : std_logic_vector(31 downto 0);
    signal pc_plus4      : std_logic_vector(31 downto 0);

    -- Instruction fields
    signal instruction   : std_logic_vector(31 downto 0);
    signal instr_opcode  : std_logic_vector(5 downto 0);  -- [31:26]
    signal instr_rs      : std_logic_vector(4 downto 0);  -- [25:21]
    signal instr_rt      : std_logic_vector(4 downto 0);  -- [20:16]
    signal instr_rd      : std_logic_vector(4 downto 0);  -- [15:11]
    signal instr_shamt   : std_logic_vector(4 downto 0);  -- [10:6]
    signal instr_funct   : std_logic_vector(5 downto 0);  -- [5:0]
    signal instr_imm16   : std_logic_vector(15 downto 0); -- [15:0] I-type
    signal instr_jaddr   : std_logic_vector(25 downto 0); -- [25:0] J-type

    -- Control signals
    signal ctrl_reg_dst      : std_logic_vector(1 downto 0);
    signal ctrl_mem_to_reg   : std_logic_vector(1 downto 0);
    signal ctrl_alu_op       : std_logic_vector(1 downto 0);
    signal ctrl_jump         : std_logic;
    signal ctrl_branch       : std_logic;
    signal ctrl_mem_read     : std_logic;
    signal ctrl_mem_write    : std_logic;
    signal ctrl_alu_src      : std_logic;
    signal ctrl_sign_or_zero : std_logic;
    signal ctrl_reg_write    : std_logic;

    -- Register file
    signal reg_write_dest    : std_logic_vector(4 downto 0);
    signal reg_read_data_1   : std_logic_vector(31 downto 0);
    signal reg_read_data_2   : std_logic_vector(31 downto 0);
    signal reg_write_data    : std_logic_vector(31 downto 0);

    -- Sign/zero extend
    signal imm_extended      : std_logic_vector(31 downto 0);

    -- ALU
    signal alu_ctrl_out      : std_logic_vector(2 downto 0);
    signal alu_operand_b     : std_logic_vector(31 downto 0);
    signal alu_result        : std_logic_vector(31 downto 0);
    signal alu_zero          : std_logic;

    -- Memory
    signal mem_read_data     : std_logic_vector(31 downto 0);

    -- Branch / jump targets
    signal branch_target     : std_logic_vector(31 downto 0);
    signal jump_target       : std_logic_vector(31 downto 0);
    signal branch_taken      : std_logic;

begin

    -- -------------------------------------------------------
    -- Instruction field extraction
    -- -------------------------------------------------------
    instr_opcode <= instruction(31 downto 26);
    instr_rs     <= instruction(25 downto 21);
    instr_rt     <= instruction(20 downto 16);
    instr_rd     <= instruction(15 downto 11);
    instr_shamt  <= instruction(10 downto 6);
    instr_funct  <= instruction(5  downto 0);
    instr_imm16  <= instruction(15 downto 0);
    instr_jaddr  <= instruction(25 downto 0);

    -- -------------------------------------------------------
    -- Sign / zero extend immediate  (16 → 32 bits)
    -- -------------------------------------------------------
    imm_extended <= std_logic_vector(resize(signed(instr_imm16), 32))
                    when ctrl_sign_or_zero = '1'
                    else std_logic_vector(resize(unsigned(instr_imm16), 32));

    -- -------------------------------------------------------
    -- PC arithmetic
    -- -------------------------------------------------------
    pc_plus4 <= std_logic_vector(unsigned(pc_current) + 4);

    -- Branch target = PC+4 + (sign-extended offset << 2)
    branch_target <= std_logic_vector(
        unsigned(pc_plus4) +
        unsigned(imm_extended(29 downto 0) & "00"));

    -- Jump target = { PC+4[31:28], J-address, 00 }
    jump_target <= pc_plus4(31 downto 28) & instr_jaddr & "00";

    branch_taken <= ctrl_branch and alu_zero;

    -- PC MUX: jump > branch > sequential
    pc_next <=
        jump_target   when ctrl_jump = '1'       else
        branch_target when branch_taken = '1'    else
        pc_plus4;

    -- -------------------------------------------------------
    -- PC Register
    -- -------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            pc_current <= (others => '0');
        elsif rising_edge(clk) then
            pc_current <= pc_next;
        end if;
    end process;

    -- -------------------------------------------------------
    -- Register write destination MUX
    --   "00" → rt   (I-type)
    --   "01" → rd   (R-type)
    --   "10" → R31  (JAL, not yet implemented)
    -- -------------------------------------------------------
    reg_write_dest <=
        instr_rt           when ctrl_reg_dst = "00" else
        instr_rd           when ctrl_reg_dst = "01" else
        "11111";           -- R31 for JAL

    -- -------------------------------------------------------
    -- ALU second-operand MUX
    -- -------------------------------------------------------
    alu_operand_b <= imm_extended      when ctrl_alu_src = '1'
                     else reg_read_data_2;

    -- -------------------------------------------------------
    -- Write-back MUX
    --   "00" → ALU result
    --   "01" → memory read data
    --   "10" → PC+4 (JAL)
    -- -------------------------------------------------------
    reg_write_data <=
        alu_result     when ctrl_mem_to_reg = "00" else
        mem_read_data  when ctrl_mem_to_reg = "01" else
        pc_plus4;

    -- -------------------------------------------------------
    -- Component instantiations
    -- -------------------------------------------------------

    U_IMEM : Instruction_Memory
        port map (
            pc          => pc_current,
            instruction => instruction
        );

    U_CTRL : Control_Unit
        port map (
            opcode       => instr_opcode,
            reset        => reset,
            reg_dst      => ctrl_reg_dst,
            mem_to_reg   => ctrl_mem_to_reg,
            alu_op       => ctrl_alu_op,
            jump         => ctrl_jump,
            branch       => ctrl_branch,
            mem_read     => ctrl_mem_read,
            mem_write    => ctrl_mem_write,
            alu_src      => ctrl_alu_src,
            sign_or_zero => ctrl_sign_or_zero,
            reg_write    => ctrl_reg_write
        );

    U_RF : Register_File
        port map (
            clk             => clk,
            rst             => reset,
            reg_write_en    => ctrl_reg_write,
            reg_write_dest  => reg_write_dest,
            reg_write_data  => reg_write_data,
            reg_read_addr_1 => instr_rs,
            reg_read_addr_2 => instr_rt,
            reg_read_data_1 => reg_read_data_1,
            reg_read_data_2 => reg_read_data_2
        );

    U_ALU_CTRL : ALU_Control
        port map (
            ALUOp       => ctrl_alu_op,
            ALU_Funct   => instr_funct,
            ALU_Control => alu_ctrl_out
        );

    U_ALU : ALU
        port map (
            a           => reg_read_data_1,
            b           => alu_operand_b,
            alu_control => alu_ctrl_out,
            alu_result  => alu_result,
            zero        => alu_zero
        );

    U_DMEM : Data_Memory
        port map (
            clk             => clk,
            mem_access_addr => alu_result,
            mem_write_data  => reg_read_data_2,
            mem_write_en    => ctrl_mem_write,
            mem_read        => ctrl_mem_read,
            mem_read_data   => mem_read_data
        );

end Structural;

-- =============================================================
-- REVIEW NOTES
-- 1. All internal signals are 32-bit. The 16-bit version had
--    no explicit top-level; this structural design shows all
--    interconnections clearly.
-- 2. PC increments by 4 (byte addressing). The 16-bit version
--    incremented by 2; switching to 4 is required for 32-bit.
-- 3. Branch target = PC+4 + (imm16 << 2). The left-shift is
--    implemented by concatenating "00" to the lower 30 bits of
--    imm_extended rather than using a barrel shifter.
-- 4. Jump target = PC+4[31:28] & J-address[25:0] & "00" —
--    standard MIPS pseudo-direct jump addressing.
-- 5. Jump takes priority over branch in the PC MUX (matches
--    standard MIPS pipeline convention).
-- 6. SW feeds reg_read_data_2 directly into Data_Memory's
--    mem_write_data port (the value to store is always rt).
-- 7. All MUX decisions are concurrent signal assignments,
--    keeping the architecture purely combinational except for
--    the PC register and Data/Register write-back (clocked).
-- =============================================================
