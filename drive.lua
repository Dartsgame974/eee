-- Find monitors automatically
local monitorLeft = peripheral.find("monitor") -- Automatically find the left monitor
local monitorRight = peripheral.find("monitor") -- Automatically find the right monitor

-- Ensure both monitors are found, else display an error
if not monitorLeft or not monitorRight then
    print("Error: Both monitors must be connected!")
    return
end

-- Set monitor scales
monitorLeft.setTextScale(1)
monitorRight.setTextScale(1)

-- Find RS Bridge peripheral
local rsBridge = peripheral.find("rsBridge")

-- Handle RS Bridge not found
if not rsBridge then
    print("Error: RS Bridge peripheral not found!")
    return
end

-- Function to format numbers into K (thousand), M (million), etc.
local function formatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Function to determine the bar color based on the percentage of usage
local function getBarColor(percentage)
    if percentage < 0.5 then
        return colors.green
    elseif percentage < 0.75 then
        return colors.yellow
    elseif percentage < 0.9 then
        return colors.orange
    else
        return colors.red
    end
end

-- Function to draw a vertical progress bar
local function drawVerticalBar(monitor, used, total, label)
    monitor.clear()

    -- Get monitor size
    local width, height = monitor.getSize()

    -- Calculate the ratio (percentage) of usage
    local ratio = used / total
    local filledHeight = math.floor(ratio * height)

    -- Calculate the color based on the percentage of usage
    local barColor = getBarColor(ratio)

    -- Draw the vertical bar that scales based on usage
    for y = 1, height do
        monitor.setCursorPos(1, height - y + 1)
        monitor.setBackgroundColor(y <= filledHeight and barColor or colors.gray)
        monitor.write(string.rep(" ", width)) -- Make the bar take the full width
    end

    -- Draw a line to represent the free space boundary
    monitor.setBackgroundColor(colors.white)
    monitor.setCursorPos(1, height - filledHeight + 1)
    monitor.write(string.rep("-", width))

    -- Display the label (Items or Fluids) and the usage at the top
    monitor.setCursorPos(1, 1)
    monitor.setTextColor(colors.white)
    monitor.write(string.rep(" ", width)) -- Clear the line

    monitor.setCursorPos(math.floor((width - #label) / 2), 1)
    monitor.write(label) -- Display the label

    -- Display the used and total storage in shortened format
    local storageText = formatNumber(used) .. " / " .. formatNumber(total)
    monitor.setCursorPos(math.floor((width - #storageText) / 2), 2)
    monitor.write(storageText) -- Center the storage usage text
end

-- Function to display storage usage on both monitors
local function displayStorageUsage()
    -- Get item storage information
    local totalItemStorage = rsBridge.getMaxItemDiskStorage()
    local usedItemStorage = 0
    for _, item in pairs(rsBridge.listItems()) do
        usedItemStorage = usedItemStorage + item.amount
    end

    -- Get fluid storage information
    local totalFluidStorage = rsBridge.getMaxFluidDiskStorage()
    local usedFluidStorage = 0
    for _, fluid in pairs(rsBridge.listFluids()) do
        usedFluidStorage = usedFluidStorage + fluid.amount
    end

    -- Display the vertical progress bar for items on the left monitor
    drawVerticalBar(monitorLeft, usedItemStorage, totalItemStorage, "Items")

    -- Display the vertical progress bar for fluids on the right monitor
    drawVerticalBar(monitorRight, usedFluidStorage, totalFluidStorage, "Fluids")
end

-- Main loop to update the display every 5 seconds
while true do
    displayStorageUsage()
    sleep(5) -- Update every 5 seconds
end
