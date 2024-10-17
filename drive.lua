-- Initialize peripherals and variables
local monitor = peripheral.find("monitor") -- Assuming you have a monitor connected
local rsBridge = peripheral.find("rsBridge") -- Assuming RS Bridge is correctly connected

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

-- Function to draw a stylized progress bar with rounded edges
local function drawProgressBar(used, total, width)
    local ratio = used / total
    local filledLength = math.floor(ratio * width)

    -- Draw the bar
    monitor.setTextColor(colors.lightGray)
    monitor.write("[")
    monitor.setTextColor(colors.green)
    monitor.write(string.rep("=", filledLength))
    monitor.setTextColor(colors.gray)
    monitor.write(string.rep("-", width - filledLength))
    monitor.setTextColor(colors.lightGray)
    monitor.write("]")
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
    monitor.setCursorPos(1, 3)
    centerText("[", 3) -- Left side of the bar
    monitor.setCursorPos(w-1, 3) -- Position the right side
    monitor.write("]") -- Right side of the bar

    monitor.setCursorPos(2, 3)
    drawProgressBar(usedStorage, totalStorage, w - 2)

    -- Display the shortened storage numbers below the bar
    local storageText = formatNumber(usedStorage) .. " / " .. formatNumber(totalStorage)
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.green)
    centerText(storageText, 5)

    -- Display the free space centered
    local freeText = "Free: " .. formatNumber(freeStorage)
    monitor.setTextColor(colors.lightGray)
    centerText(freeText, 7)

if usedStorage >= totalStorage then
    monitor.clear()
    local flicker = true
    while usedStorage >= totalStorage do
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
    end
    monitor.clear()
    displayStorage() -- Re-display storage info when space is freed
end
