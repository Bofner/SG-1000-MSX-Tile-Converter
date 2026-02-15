# SG-1000 and MSX Graphics Mode II Graphics Exporter from Aseprite
# AsepriteのSG-1000とMSXのGraphics Mode IIグラフィックエキスポータ

Export Aseprite files into WLA-DX-ready Z80 assembly data for the SG-1000 and MSX! Just add the script to your script folder in Aseprite!

Regular SG-1000 and MSX Graphics Mode II restrictions must be abided by, and for the time being, background graphics must be 256x192, 
however, sprites can be just about any size that is a multiple of either 8 or 16 depending on the desired sprite size. 

## Here's how it works:

This is the Splash screen for Steelfinger Studios. It uses both the background and sprites in order to get around the color limitations
of Graphics Mode II. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/step1.png)

 We'll start by removing the sprite layer, and export only the background tiles. Just setting the sprite layer to invisible will work
 just fine. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/withSprites.png)

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/2ColorsPerHorizontal.png)

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/step2.png)

 Next we want to run the script, which is called SG-1000 Export. I haven't tested it, but in theory this format should be compatible with MSX 1 
 graphics, as well as the Colecovision, since they all use the same graphics chip. But since I only own a Sega Mark III (which is SG-1000 compatible) 
 it's the only system I can verify completely. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/step3.png)

 Select the "Export Background" option.

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/step4.png)

 And choose where you want to save your 3 file types, as well as what to name them. This SG-1000 needs 3 different files in order to 
 create a background. It needs the 8x8 tile patterns and their corresponding color values, as well as the tile map for the screen display. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/step5.png)

 The data is exported as a .inc file to be included in your assembly file. Specifically, the color and tile pattern files have a special formatting.
 They both include inner labels for helping with data storage when it comes to implementing it in Z80 Assembly. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/tilePatterns.png)

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/ColorMap.png)

 The tile map file is broken up into 3 sections, each of which corresponds to that section of the screen for easy debugging and 
 graphic checks. This is also how the graphics are rendered, in 3 distinct chunks. 

 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/tileMap.png)

 To implement it into an assembly program, I recommend the using the sub-labels automatically printed in the .inc files, in addition To
 your own when you import them, especially for the color map and tile patterns. 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/importBG.png)
 
 
 The screen is broken up into 3 parts, each part starting at a different point in
 VRAM. 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/backgroundASM.png)


Next we can export the sprites. We can start by giving them their own file.

![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/spritesOnlyOnBGpng.png)

![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesStep1.png)


 Then we can use the SG-1000 Exporter again, but this time export as a sprite.
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesData.png)
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesStep3.png)
 
 In this example, the drop shadow for the S and F are arranged to be a 16x16 sprite, so we will check the box. 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesStep4.png)
 
 Our data will be displayed just as it is for the tile patterns of the background, but this time we don't 
 need to worry about adding the sub-labels. 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesData.png)
 
 You can then import the graphics in your ASM program.
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/importSprites.png)
 
 For getting the graphics into VRAM, just make sure that you are pointing to the correct address. The address for 
 where every one of these files should go is determined by the the VDP registers, so make sure you know how your registers
 are set when trying to display graphics. 
 
 The color of the sprites are controlled in the Sprite Attribute Table (SAT). Each sprite gets 4 bytes, which correspond to 
 the Y-position, X-position, Tile Pattern and Color respectively. You can see I've written 7 sprites to the SAT for the drop 
 shadow of the SFS, and the subtext. And after the last sprite, I added an extra byte, 0xD0, which acts as a terminator byte
 and tells the VDP to stop drawing sprites. 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfSpritesASM.png)
 
 I've only gone over the graphic logic, but if we can fill out the rest of the boilerplate assembly to get a game actually up
 and running, then we can open up an emulator like BizHawk and take a look at our results...
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/emulatorResult.png)
 
 Even better, we can try running on real hardware! Unfortunately, as mentioned earlier, I only have access to a Sega Mark III, and
 unfortunately, the Mark III has notoriously poor colors chosen for its legacy graphics modes. Nonetheless, here it is running
 on a real Mark III, in SG-1000 compatibillity mode! 
 
 ![](https://github.com/Bofner/SG-1000-MSX-Tile-Converter/blob/master/images/sfsMarkIII.png)
 
 If you have any questions, feel free to reach out! 
 