---------------------------------------------------------------------------------
--                      Moon Alien Part II - Tang Nano 9k
--                       Original Code by Katsumi Degawa
--
--                         Modified for Tang Nano 9k 
--                             by pinballwiz.org 
--                                11/08/2025
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   LCtrl : Fire
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity moonalien2_top is
port(
	Clock_27    : in std_logic;
    I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic; 
	O_VIDEO_G	: out std_logic;
	O_VIDEO_B	: out std_logic;
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
    ps2_clk     : in std_logic;
    ps2_dat     : inout std_logic;
    led         : out std_logic_vector(5 downto 0) 
 );
end moonalien2_top;
------------------------------------------------------------------------------
architecture struct of moonalien2_top is

 signal clock_36   : std_logic;
 signal clock_24   : std_logic;
 signal clock_18   : std_logic;
 signal clock_9    : std_logic;
 --
 signal video_r    : std_logic_vector(2 downto 0);
 signal video_g    : std_logic_vector(2 downto 0);
 signal video_b    : std_logic_vector(1 downto 0);
 signal h_sync     : std_logic;
 signal v_sync	   : std_logic;
 -- 
 signal video_r_x2 : std_logic_vector(5 downto 0);
 signal video_g_x2 : std_logic_vector(5 downto 0);
 signal video_b_x2 : std_logic_vector(5 downto 0);
 signal hsync_x2   : std_logic;
 signal vsync_x2   : std_logic;
 -- 
 signal reset      : std_logic;
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(8 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
  component scandoubler 
    port (
    clk_sys 	: in std_logic;
    scanlines	: in std_logic_vector (1 downto 0);
    hs_in 		: in std_logic;
    vs_in 		: in std_logic;
    r_in        : in std_logic_vector (5 downto 0);
    g_in 	    : in std_logic_vector (5 downto 0);
    b_in		: in std_logic_vector (5 downto 0);
    hs_out 		: out std_logic;
    vs_out 		: out std_logic;
    r_out 		: out std_logic_vector (5 downto 0);
    g_out 		: out std_logic_vector (5 downto 0);
    b_out 		: out std_logic_vector (5 downto 0)
        );
  end component; 
---------------------------------------------------------------------------
component Gowin_rPLL
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;
---------------------------------------------------------------------------
component Gowin_rPLL2
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;
---------------------------------------------------------------------------
begin

reset <= not I_RESET;
---------------------------------------------------------------------------
-- Clocks
Clock1: Gowin_rPLL
    port map (
        clkout => clock_36,
        clkin => Clock_27
    );
--
Clock2: Gowin_rPLL2
    port map (
        clkout => clock_24,
        clkin => Clock_27
    );
---------------------------------------------------------------------------
-- Clocks Divide

process(clock_36)
begin
 if falling_edge(clock_36) then
  clock_18 <= not clock_18;
 end if; 
end process;
--
process (clock_18)
begin
 if rising_edge(clock_18) then
  clock_9  <= not clock_9;
 end if;
end process;
---------------------------------------------------------------------------
-- Main

galaxian : entity work.galaxian
  port map (
 CLK_36M        => clock_36,
 I_RESET_SWn    => reset,
 AD             => AD,
 W_R            => video_r,
 W_G            => video_g,
 W_B            => video_b,
 hsync          => h_sync,
 vsync   	    => v_sync,
 I_SW           => '0' & joy_BBBBFRLDU(6) & joy_BBBBFRLDU(7) & joy_BBBBFRLDU(5) & joy_BBBBFRLDU(4) & joy_BBBBFRLDU(3) & joy_BBBBFRLDU(2) & joy_BBBBFRLDU(1) & joy_BBBBFRLDU(0),
 O_AUDIO_L      => O_AUDIO_L,
 O_AUDIO_R      => O_AUDIO_R
   );
---------------------------------------------------------------------------
-- DoubleScan

  u_dblscan : scandoubler
    port map (
		clk_sys => clock_24,
		r_in => "000" & video_r,
		g_in => "000" & video_g,
		b_in => "0000" & video_b,
		hs_in => h_sync,
		vs_in => v_sync,
		r_out => video_r_x2,
		g_out => video_g_x2,
		b_out => video_b_x2,
		hs_out => hsync_x2,
		vs_out => vsync_x2,
		scanlines => "00"
	);
---------------------------------------------------------------------------
-- to output

	O_VIDEO_R 	<= video_r_x2(0);
	O_VIDEO_G 	<= video_g_x2(0);
	O_VIDEO_B 	<= video_b_x2(0);
	O_HSYNC     <= hsync_x2;
	O_VSYNC     <= vsync_x2;
---------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
----------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
----------------------------------------------------------------------------
-- debug

process(reset, clock_27)
begin
  if reset = '1' then
    clock_4hz <= '0';
    counter_clk <= (others => '0');
  else
    if rising_edge(clock_27) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(5 downto 0) <= not AD(9 downto 4);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
----------------------------------------------------------------------------
end struct;