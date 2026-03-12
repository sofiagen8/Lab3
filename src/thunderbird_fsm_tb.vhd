--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
    port(i_clk, i_reset : in std_logic;
        i_left, i_right : in std_logic;
        o_lights_L : out  std_logic_vector(2 downto 0);
        o_lights_R : out std_logic_vector(2 downto 0) --inside right taillight => RA=LSB of o_lights_R, RC=MSB
	  );
	end component thunderbird_fsm;

	-- test I/O signals
	signal w_left : std_logic := '0';
	signal w_right : std_logic := '0';
	signal w_reset : std_logic := '0';
	signal w_clk : std_logic := '0';
	
	--Outputs
	signal w_blinker_R : std_logic_vector(2 downto 0) := "000";
	signal w_blinker_L : std_logic_vector(2 downto 0) := "000";	
	
	-- constants
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map(
          i_reset => w_reset,
          i_clk => w_clk,
          i_left => w_left,
          i_right => w_right,
          o_lights_L => w_blinker_L,
          o_lights_R => w_blinker_R
        );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
        begin
            w_clk <= '0';
            wait for k_clk_period/2;
            w_clk <= '1';
            wait for k_clk_period/2;
        end process;
	
	-- Simulation process
	-- Use 220 ns for simulation
	sim_proc: process
	begin
		-- sequential timing		
		w_reset <= '1';
		wait for k_clk_period*1;
		  assert w_blinker_L = "000" report "bad reset" severity failure;
		  assert w_blinker_R = "000" report "bad reset" severity failure;
		
		w_reset <= '0';
		wait for k_clk_period*1;
		
		-- right blinker test --need to create more test benches--left off here
    w_right <= '1'; wait for k_clk_period;
      assert w_blinker_R = "001" report "initial blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_R = "011" report "second blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_R = "111" report "full blinker" severity failure;
 
    --left blinker test
    w_left <= '1'; wait for k_clk_period;
      assert w_blinker_L = "001" report "initial left blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_L = "011" report "second left blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_L = "111" report "full left blinker" severity failure;
 
    --hazards blinker test
    w_left <= '1'; w_right <= '1'; wait for k_clk_period;
      assert w_blinker_R = "111" report "full blinker" severity failure;
      assert w_blinker_L = "111" report "full blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_R = "111" report "full blinker" severity failure;
      assert w_blinker_L = "111" report "full blinker" severity failure;
      
      --when left is still on after reset called, repeat pattern
     w_left <= '1'; w_reset <= '1'; wait for k_clk_period;
      assert w_blinker_L = "100" report "initial blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_L = "110" report "second blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_L = "111" report "full blinker" severity failure;
      
      --when right is still on after reset called, repeat pattern
     w_right <= '1'; w_reset <= '1'; wait for k_clk_period;
      assert w_blinker_R = "100" report "initial blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_R = "110" report "second blinker" severity failure;
      wait for k_clk_period;
      assert w_blinker_R = "111" report "full blinker" severity failure;
      
      --testing off
      w_right <= '0'; wait for k_clk_period;
      assert w_blinker_R = "000" report "blinker off" severity failure;
       
      w_left <= '0'; wait for k_clk_period;
      assert w_blinker_L = "000" report "blinker off" severity failure;
      
      
      
		wait;
	end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	
	-----------------------------------------------------	
	
end test_bench;
