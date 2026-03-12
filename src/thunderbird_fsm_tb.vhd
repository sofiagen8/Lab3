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
          o_lights_L => w_blinker_L, --no idea if this works, but come back to if logic/runtime errors
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
	begin --ALL TEST BENCHES BELOW ARE COPY/PASTED FROM ICE4
		-- sequential timing		
		w_reset <= '1';
		wait for k_clk_period*1;
		  assert w_stoplight = "010" report "bad reset" severity failure;
		
		w_reset <= '0';
		wait for k_clk_period*1;
		
		-- red light
		w_C <= '0'; wait for k_clk_period;
          assert w_stoplight = "100" report "should be red when no car" severity failure;
		-- car shows up at red light
        w_C <= '1'; wait for k_clk_period;
            assert w_stoplight = "001" report "should be green when car present" severity failure;
        wait for k_clk_period * 3; -- stay green
            assert w_stoplight = "001" report "should be green when car present" severity failure;
        -- go to yellow
        w_C <= '0'; wait for k_clk_period;
            assert w_stoplight = "010" report "should be yellow when cars done" severity failure;
        wait for k_clk_period; -- time to go to red
            assert w_stoplight = "100" report "did not go red after yellow" severity failure;
        
        -- reset and test yellow to red even if car
        w_reset <= '1'; w_C <= '1';
            wait for k_clk_period;
        w_reset <= '0';
          assert w_stoplight = "010" report "bad reset" severity failure;
        wait for k_clk_period;
            assert w_stoplight = "100" report "skipped red after yellow" severity failure;
        wait for k_clk_period;
            assert w_stoplight = "001" report "should be green when car present" severity failure;
	
		wait;
	end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	
	-----------------------------------------------------	
	
end test_bench;
