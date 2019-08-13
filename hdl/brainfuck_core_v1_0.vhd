library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity brainfuck_core_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface command_AXIS
		C_command_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface data_in_AXIS
		C_data_in_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Master Bus Interface data_out_AXIS
		C_data_out_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface command_AXIS
		command_axis_aclk	: in std_logic;
		command_axis_tready	: out std_logic;
		command_axis_tdata	: in std_logic_vector(C_command_AXIS_TDATA_WIDTH-1 downto 0);
		command_axis_tvalid	: in std_logic;
        command_axis_aresetn: in std_logic;
  
  
		-- Ports of Axi Slave Bus Interface data_in_AXIS
		data_in_axis_aclk	: in std_logic;
		data_in_axis_tready	: out std_logic;
		data_in_axis_tdata	: in std_logic_vector(C_data_in_AXIS_TDATA_WIDTH-1 downto 0);
		data_in_axis_tvalid	: in std_logic;
        data_in_axis_aresetn: in std_logic;
        
		-- Ports of Axi Master Bus Interface data_out_AXIS
		data_out_axis_aclk	: in std_logic;
		data_out_axis_tvalid	: out std_logic;
		data_out_axis_tdata	: out std_logic_vector(C_data_out_AXIS_TDATA_WIDTH-1 downto 0);
		data_out_axis_tready	: in std_logic;
		data_out_axis_aresetn: in std_logic
		
	);
end brainfuck_core_v1_0;

architecture arch_imp of brainfuck_core_v1_0 is

	-- component declaration
	component tiny_fifo is
      generic (
        GC_WIDTH : integer :=  8;  -- FIFO data width
        GC_DEPTH : integer := 32); -- FIFO data depth, <= 32
      port (
        clk            : in std_logic;
        -- FIFO data input
        fifo_in_data   : in  std_logic_vector(GC_WIDTH-1 downto 0);
        fifo_in_valid  : in  std_logic;
        fifo_in_ready  : out std_logic := '0';
        -- FIFO data output
        fifo_out_data  : out std_logic_vector(GC_WIDTH-1 downto 0) := (others => '0');
        fifo_out_valid : out std_logic := '0';
        fifo_out_ready : in  std_logic;
        
        -- status signals
        fifo_index     : out signed(5 downto 0));
    end component tiny_fifo;



    --Signals
    
    signal command_data: std_logic_vector(7 downto 0);
    signal command_valid: std_logic;
    signal command_ready: std_logic;
    
    signal data_in_data: std_logic_vector(C_data_in_AXIS_TDATA_WIDTH-1 downto 0);
    signal data_in_valid: std_logic;
    signal data_in_ready: std_logic;
    
    signal data_out_data: std_logic_vector(C_data_out_AXIS_TDATA_WIDTH-1 downto 0);
    signal data_out_valid: std_logic;
    signal data_out_ready: std_logic;
    
    signal rst_n : std_logic;
    signal ptr: integer := 0;
    
    
    constant inc_p : std_logic_vector(7 downto 0) := (0 => '1', others => '0');
    constant dec_p : std_logic_vector(7 downto 0) := (1 => '1', others => '0');
    constant inc_d : std_logic_vector(7 downto 0) := (2 => '1', others => '0');
    constant dec_d : std_logic_vector(7 downto 0) := (3 => '1', others => '0');
    constant output_d : std_logic_vector(7 downto 0) := (4 => '1', others => '0');
    constant input_d : std_logic_vector(7 downto 0) := (5 => '1', others => '0');
    constant jump_f : std_logic_vector(7 downto 0) := (6 => '1', others => '0');
    constant jump_b : std_logic_vector(7 downto 0) := (7 => '1', others => '0');
begin

-- Instantiation of Axi Bus Interface command_AXIS
brainfuck_core_v1_0_command_AXIS_inst : tiny_fifo
	generic map (
		GC_WIDTH => 8,
		GC_DEPTH => 32
	)
	port map (
		clk	=> command_axis_aclk,
		fifo_in_ready	=> command_axis_tready,
		fifo_in_data	=> command_axis_tdata(7 downto 0),
		fifo_in_valid	=> command_axis_tvalid,
		fifo_index => open,
		fifo_out_data => command_data,
		fifo_out_valid => command_valid,
		fifo_out_ready => command_ready
	);

-- Instantiation of Axi Bus Interface data_in_AXIS
brainfuck_core_v1_0_data_in_AXIS_inst : tiny_fifo
	generic map (
		GC_WIDTH => C_data_in_AXIS_TDATA_WIDTH,
		GC_DEPTH => 32
	)
	port map (
		clk	=> data_in_axis_aclk,
		fifo_in_ready	=> data_in_axis_tready,
		fifo_in_data	=> data_in_axis_tdata,
		fifo_in_valid	=> data_in_axis_tvalid,
		fifo_index => open,
		fifo_out_data => data_in_data,
		fifo_out_valid => data_in_valid,
		fifo_out_ready => data_in_ready
	);

-- Instantiation of Axi Bus Interface data_out_AXIS
brainfuck_core_v1_0_data_out_AXIS_inst : tiny_fifo
	generic map (
		GC_WIDTH => C_data_out_AXIS_TDATA_WIDTH,
		GC_DEPTH => 32
	)
	port map (
		clk	=> data_out_axis_aclk,
		fifo_out_valid	=> data_out_axis_tvalid,
		fifo_out_data	=> data_out_axis_tdata,
		fifo_out_ready	=> data_out_axis_tready,
		fifo_index => open,
		fifo_in_ready	=> data_out_ready,
		fifo_in_data	=> data_out_data,
		fifo_in_valid	=> data_out_valid
	);

	-- Add user logic here
	
	
	rst_n <= command_axis_aresetn and data_in_axis_aresetn and data_out_axis_aresetn;
	
	
    data_out_data <= data_in_data;
    data_out_valid <= data_in_valid;
    data_in_ready <= data_out_ready;
	-- User logic ends

end arch_imp;
