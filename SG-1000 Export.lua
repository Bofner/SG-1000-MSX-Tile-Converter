local sprite = app.activeSprite
-- Globals to be considered as constants
local TILE = 1
local MAP = 0
local spriteFullPath
local spriteFileName

--Grab the title of our aseprite file
if sprite then
    spriteFullPath = sprite.filename
    spriteFilePath = spriteFullPath:match("(.+)%..+$")
    spriteFileName = spriteFullPath:match("([^/\\]+)$"):match("(.+)%..+$")
end

-- Get a copy of the current sprite as a single layer
local frame = app.activeFrame
local img = Image(sprite.width, sprite.height, sprite.colorMode)
img:drawSprite(sprite, frame)


-- Check if this is a new Tile Pattern, or a duplicate
local function compareTilePatterns(tilePatternMaster, proposedTilePattern, colorMapMaster, proposedColorMap)
    local sameTilePattern = true
    -- If we haven't saved a tile pattern yet, then just save it
    if #tilePatternMaster < 1 then
        return -1
    end
    -- Check if there are any of the same tile patterns in our table already
    for tile = 1, #tilePatternMaster, 1 do
        sameTilePattern = true
        for row = 1, #tilePatternMaster[tile], 1 do
            -- If a row is different, then we can skip the rest of the pattern, since it's not a duplicate
            if tilePatternMaster[tile][row] ~= proposedTilePattern[row] then
                sameTilePattern = false
                break
            elseif colorMapMaster[tile][row] ~= proposedColorMap[row] then
                sameTilePattern = false
                break
            end    

        end
        -- If we make it through and the tile was the same, then it's a duplicate
        if sameTilePattern == true then
            return tile -1 -- Stupid Lua 1 indexing messing with old 0-indexed hardware
        end
        
    end
    return -1
end

-- Function for getting our tile data etc
local function recordTiles(currentX, currentY, numTiles, tilePatternTable, tileMapTable, colorMapTable)
    -- We need to go through 256 tiles, 32 x 16
    local tileCount = numTiles
    local tileWidth = 8
    local tileHeight = 8
    local origX = currentX
    local origY = currentY
    --[[  local tilePatternTable = {}
    local tileMapTable = {}
    local colorMapTable = {} ]]
    local colorON = -1
    local colorOFF = -1
    local prevColorON = 1           -- Default it to be black
    local tilePatternByte = 0
    local colorMapByte = 0
    local tileMapByte = 0
    local pixelColor = 0
    local newRow = false

    -- Go through a third of the screen
    for tilePattern = 1, tileCount, 1 do
        -- Set our baseline X and Y
        origX = currentX
        origY = currentY
        -- Point tile pattern to next tile
        local tilePatternBuffer = {}
        -- Point color table map to next tile
        local colorMapBuffer = {}
        --colorMapTable[tilePattern] = {}

        -- Go down 8 pixels in a single tile
        for tilePatternRow = 1, tileHeight, 1 do
            -- A byte for writing the tile pattern one bit at a time
            local tileOnBit = 0x80
            local tilePatternByte = 0x00

            -- Go across 8 pixels in a single tile
            for tilePatternPixel = 1, tileWidth, 1 do
                -- Grab the pixel color
                pixelColor = img:getPixel(currentX, currentY)

                -- If we don't have an OFF color yet, save it
                if colorOFF == -1 then
                    colorOFF = pixelColor
                -- If we don't have a color ON yet, and this pixel ISN'T colorOFF, then save it
                elseif colorON == -1 and colorOFF ~= pixelColor then
                    colorON = pixelColor
                -- If our tile uses too many colors, throw error
                elseif pixelColor ~= colorON and pixelColor ~= colorOFF then
                    print("Pixel Color: " .. pixelColor)
                    print("Color Off: " .. colorOFF)
                    print("Color On: " .. colorON)
                    app.alert("Tile at (" .. currentX .. "," .. currentY .. ") has too many colors!")
                    return
                end

                -- Write either a ZERO or a ONE to the current TilePatternByte
                if pixelColor == colorON then
                    tilePatternByte = tilePatternByte | tileOnBit
                end
                -- Right shift, since we are working through our tile LEFT to RIGHT
                tileOnBit = tileOnBit >> 1

                -- Update our X
                currentX = currentX + 1
            end

            -- When we are out of the tile pattern pixel loop, then we've finished a row within a tile
            if tilePattern % 32 == 0 then
                currentX = origX
                newRow = true
            else
                currentX = origX
                newRow = false
            end
            -- Save our Tile Pattern Byte to the buffer
            tilePatternBuffer[tilePatternRow] = ("$" .. string.format("%02X", tilePatternByte) )
            --print("Row " .. tilePatternRow .. ": " .. tilePatternTable[tilePattern][tilePatternRow])
            -- Reset pattern savers
            tileOnBit = 0x80
            tilePatternByte = 0x00
            -- Update colors
            if colorON == -1 then
                colorON = prevColorON
            end
            -- And save to color table
            local colorByte = (colorON << 4) | colorOFF
            --[[ print(("Color: $" .. string.format("%02X", colorByte) )) ]]
            colorMapBuffer[tilePatternRow] =  ("$" .. string.format("%02X", colorByte) )
            --Then reset colors
            prevColorON = colorON
            colorON = -1
            colorOFF = -1
            -- Update our Y
            currentY = currentY + 1
        end
        -- When we finish the Tile Height loop, then we are finished with the tile
        -- Prepare for next tile
        -- If we are at the last tile in a row, then make sure to move to the next row
        if tilePattern % 32 == 0 then
                newRow = true
        end
        if newRow == true then
            currentY = origY + tileHeight
            currentX = 0 
            origX = currentX
            origY = currentY
            newRow = false                  -- Make sure to reset
        else
            currentY = origY
            currentX = origX + tileWidth
        end
            
        -- Check if this is a new Tile Pattern, or a duplicate
        tileMapNumber = compareTilePatterns(tilePatternTable, tilePatternBuffer, colorMapTable, colorMapBuffer)
        -- If it's a new pattern, then save the Tile Pattern and the associated color pattern
        if tileMapNumber == -1 then
            tilePatternTable[#tilePatternTable + 1] = {}
            colorMapTable[#colorMapTable + 1] = {}
            for row = 1, tileHeight, 1 do
                tilePatternTable[#tilePatternTable][row] = tilePatternBuffer[row]
                colorMapTable[#colorMapTable][row] = colorMapBuffer[row]
            end                            
            -- And save the Tile Pattern to the map
            tileMapTable[tilePattern] = ("$" .. string.format("%02X", #tilePatternTable - 1) )
        else
            -- And save the Tile Pattern to the map
            tileMapTable[tilePattern] = ("$" .. string.format("%02X", tileMapNumber) )
        end
    end

end

-- Function to write the Tile Pattern Data to inc files for use in SG-100/MSX projects
local function writeTilePatternToIncFile(file, tilePatternDataTop, tilePatternDataMid, tilePatternDataBot)

    local tileIncFile = io.open(file, "w")
    -- Header comment message
    tileIncFile:write("; Tile Pattern file for use with SG-1000/MSX Z80 Assembly programs\n; By Steelfinger Studios\n \n")
    tileIncFile:write("; First third of pattern data\n")
    tileIncFile:write("@Section0:\n")
    -- Write the first 1/3 of the pattern data
    for tile = 1, #tilePatternDataTop, 1 do
        -- Beginning of the first row of tiles
        tileIncFile:write("; Tile Pattern #" .. tile - 1)
        tileIncFile:write("\n")
        tileIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #tilePatternDataTop[tile], 1 do
            tileIncFile:write(tilePatternDataTop[tile][rowByte].." ")
        end
        tileIncFile:write(" \n")
    end
    tileIncFile:write("@Section0End:\n")
    tileIncFile:write("; Second third of pattern data\n")
    tileIncFile:write("@Section1:\n")
    -- Write the second 1/3 of the pattern data
    for tile = 1, #tilePatternDataMid, 1 do
        -- Beginning of the first row of tiles
        tileIncFile:write("; Tile Pattern #" .. tile - 1)
        tileIncFile:write("\n")
        tileIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #tilePatternDataMid[tile], 1 do
            tileIncFile:write(tilePatternDataMid[tile][rowByte].." ")
        end
        tileIncFile:write(" \n")
    end
    tileIncFile:write("@Section1End:\n")
    tileIncFile:write("; Final third of pattern data\n")
    tileIncFile:write("@Section2:\n")
    -- Write the last 1/3 of the pattern data
    for tile = 1, #tilePatternDataBot, 1 do
        -- Beginning of the first row of tiles
        tileIncFile:write("; Tile Pattern #" .. tile - 1)
        tileIncFile:write("\n")
        tileIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #tilePatternDataBot[tile], 1 do
            tileIncFile:write(tilePatternDataBot[tile][rowByte].." ")
        end
        tileIncFile:write(" \n")
    end
    tileIncFile:write("@Section2End:\n")
    tileIncFile:close();

end

-- Function to write the Color Map Data to inc files for use in SG-100/MSX projects
local function writeColorMapToIncFile(file, colorMapDataTop, colorMapDataMid, colorMapDataBot)

    local colorIncFile = io.open(file, "w")
    -- Header comment message
    colorIncFile:write("; Color Map file for use with SG-1000/MSX Z80 Assembly programs\n; By Steelfinger Studios\n \n")
    colorIncFile:write("; First third of color map data\n")
    colorIncFile:write("@Section0:\n")
    -- Write the first 1/3 of the color map data
    for tile = 1, #colorMapDataTop, 1 do
        -- Beginning of the first row of tiles
        colorIncFile:write("; Color Map for Tile Pattern #" .. tile - 1)
        colorIncFile:write("\n")
        colorIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #colorMapDataTop[tile], 1 do
            colorIncFile:write(colorMapDataTop[tile][rowByte].." ")
        end
        colorIncFile:write(" \n")
    end
    colorIncFile:write("@Section0End:\n")
    colorIncFile:write("; Second third of color map data\n")
    colorIncFile:write("@Section1:\n")
    -- Write the second 1/3 of the color map data
    for tile = 1, #colorMapDataMid, 1 do
        -- Beginning of the first row of tiles
        colorIncFile:write("; Color Map for Tile Pattern #" .. tile - 1)
        colorIncFile:write("\n")
        colorIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #colorMapDataMid[tile], 1 do
            colorIncFile:write(colorMapDataMid[tile][rowByte].." ")
        end
        colorIncFile:write(" \n")
    end
    colorIncFile:write("@Section1End:\n")
    colorIncFile:write("; Final third of color map data\n")
    colorIncFile:write("@Section2:\n")
    -- Write the last 1/3 of the color map data
    for tile = 1, #colorMapDataBot, 1 do
        -- Beginning of the first row of tiles
        colorIncFile:write("; Color Map for Tile Pattern #" .. tile - 1)
        colorIncFile:write("\n")
        colorIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #colorMapDataBot[tile], 1 do
            colorIncFile:write(colorMapDataBot[tile][rowByte].." ")
        end
        colorIncFile:write(" \n")
    end
    colorIncFile:write("@Section2End:\n")
    colorIncFile:close();

end



-- Function to write the Tile Pattern Data to inc files for use in SG-100/MSX projects
local function writeTileMapToIncFile(file, tileMapDataTop, tileMapDataMid, tileMapDataBot)

    local tileMapIncFile = io.open(file, "w")
    -- Header comment message
    tileMapIncFile:write("; Tile Map file for use with SG-1000/MSX Z80 Assembly programs\n; By Steelfinger Studios\n \n")
    tileMapIncFile:write("; First third of map data\n")
    tileMapIncFile:write("@Section0:\n")
    tileMapIncFile:write(".DB ")
    -- Write the first 1/3 of the map data
    for tile = 1, #tileMapDataTop, 1 do
        -- Write map data
        tileMapIncFile:write(tileMapDataTop[tile].." ")

        -- Make it so the data reflects the shape of the actual screen
        if tile % 32 == 0  then
            tileMapIncFile:write("\n")
            if tile ~= #tileMapDataTop then
                tileMapIncFile:write(".DB ")
            end
        end
    end
    tileMapIncFile:write("@Section0End:\n")
    
    tileMapIncFile:write("; Second third of map data\n")
    tileMapIncFile:write("@Section1:\n")
    tileMapIncFile:write(".DB ")
    -- Write the first 1/3 of the map data
    for tile = 1, #tileMapDataMid, 1 do
        -- Write map data
        tileMapIncFile:write(tileMapDataMid[tile].." ")

        -- Make it so the data reflects the shape of the actual screen
        if tile % 32 == 0  then
            tileMapIncFile:write("\n")
            if tile ~= #tileMapDataMid then
                tileMapIncFile:write(".DB ")
            end
        end
    end
    tileMapIncFile:write("\n@Section1End:\n")

    tileMapIncFile:write("; Last third of map data\n")
    tileMapIncFile:write("@Section2:\n")
    tileMapIncFile:write(".DB ")
    -- Write the first 1/3 of the map data
    for tile = 1, #tileMapDataBot, 1 do
        -- Write map data
        tileMapIncFile:write(tileMapDataBot[tile].." ")

        -- Make it so the data reflects the shape of the actual screen
        if tile % 32 == 0  then
            tileMapIncFile:write("\n")
            if tile ~= #tileMapDataBot then
                tileMapIncFile:write(".DB ")
            end
        end
    end
    tileMapIncFile:write("@Section2End:\n")
    tileMapIncFile:close();
end

-- Export drawing as a background
local function exportBackground()
    -- Check size of sprite
    if sprite.width ~= 256 or sprite.height ~= 192 then
        app.alert("Canvas needs to be 256x192")
        return
    end

    local numTiles = 256

    --Menu that pops up in Aseprite
    local dlg = Dialog()

    dlg:file{ id="tileFile",
            label="Tile-Pattern-File",
            title="SG-1000/MSX Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Tiles.inc",
            filetypes={"inc"}}
    dlg:file{ id="mapFile",
            label="Tile-Map-File",
            title="SG-1000/MSX Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Map.inc",
            filetypes={"inc"}}
    dlg:file{ id="colorFile",
            label="Color-Map-File",
            title="SG-1000/MSX Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Color.inc",
            filetypes={"inc"}}

    dlg:button{ id="ok", text="OK", focus = true}
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()
    local data = dlg.data
    local notPointer = {aBinaryValue}
    local tileBinary
    local mapBinary
    local colorBinary

    if data.ok then
        -- Tile patterns for each 1/3 of the screen
        local tilePatternTable0 = {}
        local tilePatternTable1 = {}
        local tilePatternTable2 = {}
        -- Tile Maps for each 1/3 of the screen
        local tileMapTable0 = {}
        local tileMapTable1 = {}
        local tileMapTable2 = {}
        -- Color Maps for each 1/3 of the screen
        local colorMapTable0 = {}
        local colorMapTable1 = {}
        local colorMapTable2 = {}
        -- Begin our conversion
        local x = 0
        local y = 0
        -- First 256 tiles
        recordTiles(x, y, numTiles, tilePatternTable0, tileMapTable0, colorMapTable0)
        -- Second 256 tiles conversion
        local x = 0
        local y = 64
        recordTiles(x, y, numTiles, tilePatternTable1, tileMapTable1, colorMapTable1)
        local x = 0
        local y = 128
        recordTiles(x, y, numTiles, tilePatternTable2, tileMapTable2, colorMapTable2)

        -- Write to file
        writeTilePatternToIncFile(data.tileFile, tilePatternTable0, tilePatternTable1, tilePatternTable2)
        writeTileMapToIncFile(data.mapFile, tileMapTable0, tileMapTable1, tileMapTable2)
        writeColorMapToIncFile(data.colorFile, colorMapTable0, colorMapTable1, colorMapTable2)
    end
end









-- Function for getting our tile data etc
local function recordSpriteTiles(currentX, currentY, numTiles, tilePatternTable, bigSprites)
    -- We need to go through 256 tiles, 32 x 16
    local spriteWidthTiles = sprite.width / 8
    local tileWidth = 8
    local origX = currentX
    local origY = currentY
    local colorOFF = 0              -- Make sure to set background to be 0 index
    local tilePatternByte = 0
    local colorMapByte = 0
    local tileMapByte = 0
    local pixelColor = 0
    local newRow = false
    
    local tileCount 
    local tileHeight
    -- Check size of sprite
    if bigSprites == true then
        if sprite.width % 16 ~= 0 or sprite.height % 16 ~= 0 then
            app.alert("Sprite dimensions must be a multiple of 16!")
            return
        end
        tileHeight = 16
        tileCount = numTiles / 2

    else
        tileHeight = 8
        tileCount = numTiles
    end
    
    -- Go through a third of the screen
    for tilePattern = 1, tileCount, 1 do
        -- Set our baseline X and Y
        origX = currentX
        origY = currentY
        -- Point tile pattern to next tile
        tilePatternTable[tilePattern] = {}
        -- Go down 8 pixels in a single tile
        for tilePatternRow = 1, tileHeight, 1 do
            -- A byte for writing the tile pattern one bit at a time
            local tileOnBit = 0x80
            local tilePatternByte = 0x00

            -- Go across 8 pixels in a single tile
            for tilePatternPixel = 1, tileWidth, 1 do
                -- Grab the pixel color
                pixelColor = img:getPixel(currentX, currentY)

                -- Write either a ZERO or a ONE to the current TilePatternByte
                if pixelColor ~= colorOFF then
                    tilePatternByte = tilePatternByte | tileOnBit
                end
                -- Right shift, since we are working through our tile LEFT to RIGHT
                tileOnBit = tileOnBit >> 1

                -- Update our X
                currentX = currentX + 1
            end

            -- When we are out of the tile pattern pixel loop, then we've finished a row within a tile
            if tilePattern % spriteWidthTiles == 0 then
                currentX = origX
                newRow = true
            else
                currentX = origX
                newRow = false
            end
            
            -- Save our Tile Pattern Byte to the buffer
           tilePatternTable[tilePattern][tilePatternRow] = ("$" .. string.format("%02X", tilePatternByte) )
            --print("Row " .. tilePatternRow .. ": " .. tilePatternTable[tilePattern][tilePatternRow])
            -- Reset pattern savers
            tileOnBit = 0x80
            tilePatternByte = 0x00
            -- Update our Y
            currentY = currentY + 1
        end
        -- When we finish the Tile Height loop, then we are finished with the tile
        -- Prepare for next tile
        -- If we are at the last tile in a row, then make sure to move to the next row
        if tilePattern % spriteWidthTiles == 0 then
                newRow = true
        end
        if newRow == true then
            currentY = origY + tileHeight
            currentX = 0 
            origX = currentX
            origY = currentY
            newRow = false                  -- Make sure to reset
        else
            currentY = origY
            currentX = origX + tileWidth
        end
    end
end

-- Write sprite tiles to a file
local function writeSpriteTiles(tileFile, tilePatternData)
     local tilePatternIncFile = io.open(tileFile, "w")
    -- Header comment message
    tilePatternIncFile:write("; Tile Pattern file for use with sprites on SG-1000/MSX Z80 Assembly programs\n; By Steelfinger Studios\n \n")
    -- Write the Tile Patterns
    for tile = 1, #tilePatternData, 1 do
        -- Beginning of the first row of tiles
        tilePatternIncFile:write("; Sprite Pattern #" .. tile - 1)
        tilePatternIncFile:write("\n")
        tilePatternIncFile:write(".DB ")
        -- Each tile is made of 8 bytes
        for rowByte = 1, #tilePatternData[tile], 1 do
            tilePatternIncFile:write(tilePatternData[tile][rowByte].." ")
        end
        tilePatternIncFile:write("\n")
    end
    tilePatternIncFile:close();
end


local function exportSprite()
    -- Check size of sprite
    if sprite.width % 8 ~= 0 or sprite.height % 8 ~= 0 then
        app.alert("Sprite dimensions must be a multiple of 8!")
        return
    end

    local numTiles = (sprite.width / 8) * (sprite.height / 8)

    --Menu that pops up in Aseprite
    local dlg = Dialog()

    dlg:file{ id="tileFile",
            label="Tile-Pattern-File",
            title="SG-1000/MSX Export",
            open=false,
            save=true,
            filename= spriteFilePath .. "Tiles.inc",
            filetypes={"inc"}}
    dlg:check{ id="bigSprites",
            text="Export as 16x16",
            selected=false}
    dlg:button{ id="ok", text="OK", focus = true }
    dlg:button{ id="cancel", text="Cancel" }
    dlg:show()
    local data = dlg.data

    if data.ok then
         -- Tile patterns 
        local tilePatternTable = {}
        -- Begin our conversion
        local x = 0
        local y = 0
        -- First 256 tiles
        recordSpriteTiles(x, y, numTiles, tilePatternTable, data.bigSprites )

        writeSpriteTiles(data.tileFile, tilePatternTable)
    end
end

-- Start user interaction

-- Check constrains
if sprite == nil then
  app.alert("No Sprite...")
  return
end
if sprite.colorMode ~= ColorMode.INDEXED then
  app.alert("Sprite needs to be indexed")
  return
end

local dlg = Dialog()
dlg:button{ id="background", text="Export Background" }
dlg:button{ id="sprite", text="Export Sprite" }
dlg:button{ id="cancel", text="Cancel", focus = true  }
dlg:show()
local data = dlg.data
if data.background then
    exportBackground()
elseif data.sprite then
    exportSprite()
else
    return
end



