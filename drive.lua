-- Initialize peripherals and variables
local monitor = peripheral.find("monitor") -- Assuming you have a monitor connected
local rsBridge = peripheral.find("rsBridge") -- Assuming RS Bridge is correctly connected

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

-- Function to draw a progress bar
local function drawProgressBar(used, total, length)
    local ratio = used / total
    local filledLength = math.floor(ratio * length)
    local bar = string.rep("=", filledLength) .. string.rep("-", length - filledLength)
    return bar
end

-- Main function to display storage information
local function displayStorage()
    local totalStorage = rsBridge.getMaxItemDiskStorage()
    local usedStorage = 0

    for _, item in pairs(rsBridge.listItems()) do
        usedStorage = usedStorage + item.amount
    end

    local freeStorage = totalStorage - usedStorage

    -- Clear the monitor and set the title
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.blue)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextScale(1)
    monitor.write("Google Drive")

    -- Draw the progress bar
    monitor.setCursorPos(1, 3)
    local bar = drawProgressBar(usedStorage, totalStorage, 20)
    monitor.setTextColor(colors.green)
    monitor.write(bar)

    -- Display the shortened storage numbers
    monitor.setCursorPos(1, 5)
    monitor.setTextColor(colors.green)
    monitor.write(formatNumber(usedStorage) .. "/" .. formatNumber(totalStorage))

    -- Display free storage
    monitor.setCursorPos(1, 7)
    monitor.setTextColor(colors.lightGray)
    monitor.write("Free: " .. formatNumber(freeStorage))

    -- Check if storage is full and display warning
    if usedStorage >= totalStorage then
        monitor.clear()
        monitor.setTextColor(colors.red)
        local flicker = true
        while usedStorage >= totalStorage do
            monitor.setCursorPos(1, 5)
            if flicker then
                monitor.write("STOCKAGE COMPLET!!!!")
            else
                monitor.clearLine()
            end
            flicker = not flicker
            sleep(0.5)
            usedStorage = 0
            for _, item in pairs(rsBridge.listItems()) do
                usedStorage = usedStorage + item.amount
            end
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
