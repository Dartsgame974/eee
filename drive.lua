-- Load AUKit for audio playback
local aukit = require("aukit")
local speaker = peripheral.find("speaker")
local mf = require("morefonts") -- Load More Fonts library

-- Initialize peripherals and variables
local monitor = peripheral.find("monitor")
local rsBridge = peripheral.find("rsBridge")

-- Set monitor scale and clear
monitor.setTextScale(1)
monitor.clear()

-- Format large numbers into K (thousand), M (million), etc.
local function formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Function to display "FLUID COMPLET" or "STOCKAGE COMPLET" and the storage values
local function displayMessage(message, valueUsed, valueTotal, color)
    monitor.clear() -- Clear the screen once before showing messages
    monitor.setTextColor(color)

    -- Display the message
    mf.writeOn(monitor, message, nil, 5, {
        font = "fonts/PublicPixel",
        scale = 0.5,
        anchorHor = "center",
    })
    
    sleep(2) -- Hold the message for 2 seconds
    
    -- Display storage values
    local storageText = formatNumber(valueUsed) .. " / " .. formatNumber(valueTotal)
    monitor.setCursorPos(1, 7)  -- Ensure this displays in a new line
    mf.writeOn(monitor, storageText, nil, 7, {
        font = "fonts/PublicPixel",
        scale = 0.5,
        anchorHor = "center",
    })
    
    sleep(2) -- Hold the storage value for 2 seconds
end

-- Function to play the alert sound 3 times
local function playAlert()
    for i = 1, 3 do
        aukit.play(aukit.stream.wav(io.lines("alert.wav", 48000)), speaker)
        sleep(2) -- Pause between plays to ensure it's audible
    end
end

-- Function to loop the signature sound
local function playSignatureLoop()
    while true do
        aukit.play(aukit.stream.wav(io.lines("signature.wav", 48000)), speaker)
        sleep(1) -- Repeat after a 1-second pause
    end
end

-- Main function to display storage information and handle full storage conditions
local function displayStorage()
    -- Get item storage information
    local totalItemStorage = rsBridge.getMaxItemDiskStorage()
    local usedItemStorage = 0
    for _, item in pairs(rsBridge.listItems()) do
        usedItemStorage = usedItemStorage + item.amount
    end
    local freeItemStorage = totalItemStorage - usedItemStorage

    -- Get fluid storage information
    local totalFluidStorage = rsBridge.getMaxFluidDiskStorage()
    local usedFluidStorage = 0
    for _, fluid in pairs(rsBridge.listFluids()) do
        usedFluidStorage = usedFluidStorage + fluid.amount
    end
    local freeFluidStorage = totalFluidStorage - usedFluidStorage

    -- If either item or fluid storage is full
    if freeItemStorage <= 10000 or freeFluidStorage <= 10000 then
        -- Play alert 3 times, then loop the signature sound
        playAlert()
        
        -- Display full storage messages in a loop until space is freed
        while freeItemStorage <= 10000 or freeFluidStorage <= 10000 do
            -- Display "Fluid COMPLET" message if fluid storage is full
            if freeFluidStorage <= 10000 then
                displayMessage("FLUID COMPLET!!!!", usedFluidStorage, totalFluidStorage, colors.red)
            end

            -- Display "Stockage COMPLET" message if item storage is full
            if freeItemStorage <= 10000 then
                displayMessage("STOCKAGE COMPLET!!!!", usedItemStorage, totalItemStorage, colors.red)
            end

            -- Update storage values and check if space is freed
            usedItemStorage = 0
            for _, item in pairs(rsBridge.listItems()) do
                usedItemStorage = usedItemStorage + item.amount
            end
            freeItemStorage = totalItemStorage - usedItemStorage

            usedFluidStorage = 0
            for _, fluid in pairs(rsBridge.listFluids()) do
                usedFluidStorage = usedFluidStorage + fluid.amount
            end
            freeFluidStorage = totalFluidStorage - usedFluidStorage

            sleep(1)
        end

        -- Once space is freed, stop the signature sound and reset
        monitor.clear()
        displayStorage()
    end
end -- <-- Properly close the `displayStorage` function here.

-- Main loop to update the display every 5 seconds
while true do
    displayStorage()
    sleep(5) -- Update every 5 seconds
end
