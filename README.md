# Pseudo-3D-Rendering-in-MIPS
DOOM style 3D game done in MARS MIPS Assembly

# Configuration
## Setting up The Display
This program uses the MARS Bitmap Display to render the screen. This can be found under the tools menu.

The screen resolution by default is set to 128 x 64.

In the bitmap display settings, 
make sure the `Unit Width in Pixels` and `Unit Height in Pixels` are set appropriately relative to the `Display Width in Pixels` and `Display Height in Pixels` such that,

$${\text{Display Pixels} \over \text{Unit Pixels}} = \text{128 x 64}$$

Example:

$${512 \over 4} = 128, {128 \over 4} = 64$$

Any `Display Pixels` setting is supported as long as this is adhered to.

Make sure the `Base Address for Display` is set to 0x10010000.

Click `Connect to MIPS`

## Setting up The Controls

This program uses the MARS Keyboard and Display MMIO Simulator. This can be found under the tools menu.

All that needs to be done here is to click `Connect to MIPS`, then begin typing in the `KEYBOARD` field.

## Assembly
In order to run the program correctly, make sure you have the `Project-271-AlecStobbs.asm` file currently focused and click the assemble button, then run.

You should see some blue shapes appear on the Bitmap Display if everything is setup correctly.

# Controls
`W-A-S-D` keys are mapped to forward-left-back-right movement

`Q-E` keys are mapped to left-right rotation.

# Gameplay
If all setup was done properly, you should be able to type in the MMIO simulator and move around a small 3D map with line-frame walls.

Unfortunately, MARS often loses its data in tragic boating accidents, so after re-assembling and running the game a handful of times you might notice performance fall off cliff. Simply restart MARS to fix this.
