WTFpga NG -- Stopwatch Edition
==============================

Run `make prog` and play with the design. What do the buttons do?

Compare your observations with the `assign LEDx = ...` lines in `stopwatch.v`.

Simple continous assignments
----------------------------

Change the assignments for `LED1..LED5` so that

`LED1` is on when buttons 1 and 2 are pressed.

`LED2` is on when buttons 1 and 3 are pressed.

`LED3` is on when buttons 2 and 3 are pressed.

`LED4` is on when the "user button" (`BTN_N`) is pressed. (Note that  this button is inverted, i.e. the value of `BTN_N` is zero when the button is pressed.)

`LED5` is on when any of the four buttons is pressed.

Add missing 7-segment digits
----------------------------

The module `seven_seg_hex` is converting a 4-bit binary number into a 7-bit seven segment control vector. The entries for "3" and "8" are missing add them.

Switch to decimal counting
--------------------------

The module `bcd16_increment` reads a 16-bit BCD number (a decimal digit in each nibble) and increments it by one. Replace the line `assign display_value_inc = display_value + 1;` with an instance of `bcd16_increment` so that the stop watch counts in decimal instead of hexadecimal.

(See the instances of `seven_seg_ctrl` for how to instantiate a module.)

Add RESET button
----------------

Add an if-statement to the `always @(posedge CLK)` block in the `top` module that will reset `display_value` to zero when the "user button" (`BTN_N`) is pressed.

Add START/STOP buttons
---------------------

Add a (1 bit) `running` register (initialized to zero), and change the code that increments `display_value` to only apply the increment when running is `1`.

Add if-statements to the `always @(posedge CLK)` block in the `top` module that will set `running` to `1` when `BTN3` is pressed, and reset `running` to `0` when `BTN1` is pressed. Now these two buttons function as START and STOP buttons for the stop watch.

Also change the RESET functionality so that `running` is reset to `0` when the "user button" (`BTN_N`) is pressed.

Add lap time measurement
------------------------

Finally let's also add lap time measurement: pressing the center button on the
board should display the current time for two seconds while we keep counting in
the background.

For this, we need to add a 16 bit register `lap_value` and an 8 bit register
`lap_timeout`.

`lap_timeout` should be decremented in every `clkdiv_pulse` cycle until
it reaches zero. The seven segment display should show the value of `lap_value`
instead of `display_value` when `lap_timeout` has a nonzero value.

Pressing the center button (`BTN2`) should set `lap_timeout` to 200 and copy the
value from `display_value` to `lap_value`.

Note: The syntax `a ? b : c` can be used to select value `b` when `a` is nonzero,
and value `c` otherwise.
