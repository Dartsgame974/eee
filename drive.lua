-- Load AUKit for audio playback
local aukit = require("aukit")
local speaker = peripheral.find("speaker")

-- Initialize peripherals and variables
local monitor = peripheral.find("monitor")
local rsBridge = peripheral.find("rsBridge")

-- Set monitor scale and clear
monitor.setTextScale(1.5)
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

-- Function to center text on the monitor
local function centerText(text, y)
    local w, h = monitor.getSize()
    local x = math.floor((w - #text) / 2)
    monitor.setCursorPos(x, y)
    monitor.write(text)
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
        monitor.write(" ") -- Draws a colored "square" (as close as we can get in text)
    end
    
    -- Reset the background color
    monitor.setBackgroundColor(colors.black)
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

    -- Clear the monitor
    monitor.clear()

    -- Display centered title
    monitor.setTextColor(colors.blue)
    centerText("Google Drive", 1)

    -- Draw the progress bar centered
    local w, h = monitor.getSize()
    drawProgressBar(usedStorage, totalStorage, w - 2) -- Use most of the width

    -- Display the shortened storage numbers below the bar
    local storageText = formatNumber(usedStorage) .. " / " .. formatNumber(totalStorage)
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.green)
    centerText(storageText, 5)

    -- Display the free space centered
    local freeText = "Free: " .. formatNumber(freeStorage)
    monitor.setTextColor(colors.lightGray)
    centerText(freeText, 7)

    -- Check if free storage is less than 10,000 and display warning with sound loop
    if freeStorage <= 10000 then
        monitor.clear()
        local flicker = true
        local startTime = os.clock()
        
        -- Loop the sound for 45 seconds
        while freeStorage <= 10000 do
            -- Play the sound in a loop while flickering text
            if os.clock() - startTime <= 45 then
                aukit.play(aukit.stream.wav(io.lines("alert.wav", 48000)), speaker)
            end

            -- Centered flickering full storage message
            monitor.setCursorPos(1, math.floor(h / 2))
            if flicker then
                monitor.setTextColor(colors.red)
                centerText("STOCKAGE COMPLET!!!!", math.floor(h / 2))
            else
                monitor.clearLine()
            end
            flicker = not flicker
            sleep(0.5)
            
            -- Update storage status to break out of the loop if space is freed
            usedStorage = 0
            for _, item in pairs(rsBridge.listItems()) do
                usedStorage = usedStorage + item.amount
            end
            freeStorage = totalStorage - usedStorage
        end
        monitor.clear()
        displayStorage() -- Re-display storage info when space is freed
    end
end

-- Main loop to update the display
while true do
    displayStorage()
    sleep(5) -- Update every 5 seconds
end
