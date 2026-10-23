Rewrite the current ControlCenter layout to a modular, polished and tought out grid-like system. Kinda like the iOS / NothingOS control center. ( I attached an image for reference)

## 1. The grid content

The control center grid should contain widgets that can be:

- Buttons: They do something when clicked (could have a separate control page that opens up, just like the current WifiPage and BluetoothPage)
- Sliders: Basic sliders linked to some value (e.g. volume, brightness)
- Other: Widgets that are non-interactable or have more complicated interactions. For example clocks, calendar, or even a mini music player. 

Widget sizing

- Regular buttons should always have a maximum height of 1 row, and any width from 1 to the total amount of columns. For the 1x1 buttons, only an icon should be visible.
- Sliders should have the same sizings as buttons, but with a vertical counterpart as well (1x1, 1x2, 1x3 ...)
- The rest of the widgets should have sizes of 2x2 and 2x4 for now.

## 2. The grid itself

The control center grid should be 4 columns wide and have a minimum height of 1 row, and a maximum height of 6 rows (for now, this could change in the future, so its more flexible).

## 3. About the widgets

The user should not be able to make widgets (unless they code it themselves of course), because the system would be way to complicated. So all widges should be premade, with all their sizes. Here are some of the most essential ones that you should make:

- Wifi, bluetooth, volume, brightness, power settings (shutdown, sleep, etc.), clock, calendar.

## 4. Customizing

You need to make a clean way for the user to customize this control center. It should be easy to use and understand, while also being low-key, and minimal. The user should be able to select and arrange these widgets however they want, in the given space. They should also be able to resize everything to their liking (within the sizing constrains). And of course the system should always remember the layout.

## Summary

This is a really complicated task, so take your time to make it flawless. Also keep the instructions in CLAUDE.md in mind. Think about scalability when making new components. Also think about the rest of the quickshell setup; if you need to make a critical design decision or tweak some values for the grid to work, make sure the rest of the rice is always in sync with the control center. Try to follow the design of the current setup. Write clean code, so I can read it without getting a headache.