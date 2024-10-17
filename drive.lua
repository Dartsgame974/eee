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
local function drawProgressBar(used, total, width)
    local ratio = used / total
    local filledLength = math.floor(ratio * width)

    -- Draw the progress bar with colored squares
    monitor.setCursorPos(1, 3)
    
    for i = 1, width do
        if i <= filledLength then
            -- Green for the used storage
            monitor.setBackgroundColor(colors.green)
        else
            -- Gray for the free storage
            monitor.setBackgroundColor(colors.gray)
        end
        monitor.write(" ") -- Draws a colored "square"
    end
    
    -- Reset the background color
    monitor.setBackgroundColor(colors.black)
end

-- Function to display a large centered title using More Fonts (with size 0.5)
local function displayTitle(text)
    monitor.setTextColor(colors.blue)
    mf.writeOn(monitor, text, nil, 1, {
        font = "fonts/PublicPixel", -- Choose a font here
        scale = 0.5, -- Set scale to 0.5
        anchorHor = "center",
    })
end

-- Function to display the stockage complet warning (with sound for 30 seconds)
local function displayWarning()
    local w, h = monitor.getSize()

    -- Start the warning sound for 30 seconds
    local soundStartTime = os.clock()

    -- Display flickering text for 30 seconds, sound stops but text remains
    local flickerStartTime = os.clock()
    while os.clock() - flickerStartTime <= 30 do
        -- Flickering "STOCKAGE COMPLET!!!!"
        monitor.clear()
        monitor.setTextColor(colors.red)
        mf.writeOn(monitor, "STOCKAGE COMPLET!!!!", nil, math.floor(h / 2), {
            font = "fonts/PublicPixel", -- Choose a bold font
            scale = 0.5, -- Set scale to 0.5
            anchorHor = "center",
        })

        sleep(0.5) -- Flicker every half second
        monitor.clear()
        sleep(0.5)

        -- Play alert.wav for the first 30 seconds
        if os.clock() - soundStartTime <= 30 then
            aukit.play(aukit.stream.wav(io.lines("alert.wav", 48000)), speaker)
        end
    end

    -- Continue to display the warning after 30 seconds without the sound
    while true do
        monitor.clear()
        monitor.setTextColor(colors.red)
        mf.writeOn(monitor, "STOCKAGE COMPLET!!!!", nil, math.floor(h / 2), {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })
        sleep(0.5)
        monitor.clear()
        sleep(0.5)
    end
end

-- Main function to display storage information
local function displayStorage()
    local totalStorage = rsBridge.getMaxItemDiskStorage()
    local usedStorage = 0

    -- Calculate used storage
    for _, item in pairs(rsBridge.listItems()) do
        usedStorage = usedStorage + item.amount
    end

    local freeStorage = totalStorage - usedStorage

    -- Clear the monitor and display title
    monitor.clear()
    displayTitle("Google Drive")

    -- Draw the progress bar centered
    local w, h = monitor.getSize()
    drawProgressBar(usedStorage, totalStorage, w - 2)

    -- Display the shortened storage numbers below the bar
    local storageText = formatNumber(usedStorage) .. " / " .. formatNumber(totalStorage)
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.green)
    mf.writeOn(monitor, storageText, nil, 5, { anchorHor = "center" })

    -- Display the free space centered
    local freeText = "Free: " .. formatNumber(freeStorage)
    monitor.setTextColor(colors.lightGray)
    mf.writeOn(monitor, freeText, nil, 7, { anchorHor = "center" })

    -- Check if free storage is less than 10,000 and display warning with sound loop
    if freeStorage <= 10000 then
        displayWarning()
        displayStorage() -- Re-display storage info when space is freed
    end
end

-- Main loop to update the display
while true do
    displayStorage()
    sleep(5) -- Update every 5 seconds
end
