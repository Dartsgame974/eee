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

-- Function to draw a progress bar using colored squares
local function drawProgressBar(used, total, width, yPos)
    local freeSpace = total - used
    local ratio = used / total
    local filledLength = math.floor(ratio * width)

    -- Determine the color based on free space
    if freeSpace < 2000000 then
        monitor.setBackgroundColor(colors.orange) -- Orange for less than 2M free space
    else
        monitor.setBackgroundColor(colors.green) -- Green for normal levels
    end

    -- Draw the progress bar
    monitor.setCursorPos(1, yPos)
    for i = 1, width do
        if i <= filledLength then
            monitor.write(" ") -- Draws a colored "square"
        else
            monitor.setBackgroundColor(colors.gray) -- Gray for remaining free space
            monitor.write(" ")
        end
    end
    
    -- Reset background color
    monitor.setBackgroundColor(colors.black)
end

-- Function to display the "STOCKAGE COMPLET" or "FLUID COMPLET" message
local function displayWarning(message)
    local w, h = monitor.getSize()

    -- Start the warning sound for 30 seconds
    local soundStartTime = os.clock()
    local flickerStartTime = os.clock()

    while os.clock() - flickerStartTime <= 30 do
        -- Flicker the warning message
        monitor.clear()
        monitor.setTextColor(colors.red)
        mf.writeOn(monitor, message, nil, math.floor(h / 2), {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })

        sleep(0.5)
        monitor.clear()
        sleep(0.5)

        -- Play alert.wav for the first 30 seconds
        if os.clock() - soundStartTime <= 30 then
            aukit.play(aukit.stream.wav(io.lines("alert.wav", 48000)), speaker)
        end
    end
end

-- Function to display the total combined storage of both items and fluids
local function displayTotalUsage(itemStorageUsed, itemStorageTotal, fluidStorageUsed, fluidStorageTotal)
    local totalUsed = itemStorageUsed + fluidStorageUsed
    local totalCapacity = itemStorageTotal + fluidStorageTotal

    local totalText = "Total: " .. formatNumber(totalUsed) .. " / " .. formatNumber(totalCapacity)
    monitor.setCursorPos(1, 9)
    monitor.setTextColor(colors.yellow)
    monitor.write(totalText)
end

-- Main function to display storage information
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

    -- Clear the monitor
    monitor.clear()

    -- Display the title
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.blue)
    monitor.write("Google Drive")

    -- Draw the item progress bar (y-position = 3)
    drawProgressBar(usedItemStorage, totalItemStorage, monitor.getSize() - 2, 3)

    -- Display the shortened item storage numbers below the item bar
    local itemStorageText = formatNumber(usedItemStorage) .. " / " .. formatNumber(totalItemStorage)
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.green)
    monitor.write(itemStorageText)

    -- Draw the fluid progress bar (y-position = 7)
    drawProgressBar(usedFluidStorage, totalFluidStorage, monitor.getSize() - 2, 7)

    -- Display the shortened fluid storage numbers below the fluid bar
    local fluidStorageText = formatNumber(usedFluidStorage) .. " / " .. formatNumber(totalFluidStorage)
    monitor.setCursorPos(1, 9)
    monitor.setTextColor(colors.cyan)
    monitor.write(fluidStorageText)

    -- Check if either storage type is nearly full
    if freeItemStorage <= 10000 then
        while freeItemStorage <= 10000 do
            monitor.clear()
            displayWarning("STOCKAGE COMPLET!!!!")
            displayTotalUsage(usedItemStorage, totalItemStorage, usedFluidStorage, totalFluidStorage)
            sleep(1)
        end
    elseif freeFluidStorage <= 10000 then
        while freeFluidStorage <= 10000 do
            monitor.clear()
            displayWarning("FLUID COMPLET!!!!")
            displayTotalUsage(usedItemStorage, totalItemStorage, usedFluidStorage, totalFluidStorage)
            sleep(1)
        end
    end
end

-- Main loop to update the display
while true do
    displayStorage()
    sleep(5) -- Update every 5 seconds
end
