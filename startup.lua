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

-- Function to draw a centered title
local function centerText(text, y)
    local w, _ = monitor.getSize()
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- Function to draw a color-coded progress bar
local function drawProgressBar(used, total, width, yPos)
    local ratio = used / total
    local filledLength = math.floor(ratio * width)
    
    -- Color logic based on the usage ratio
    if ratio < 0.5 then
        monitor.setBackgroundColor(colors.green)
    elseif ratio < 0.75 then
        monitor.setBackgroundColor(colors.yellow)
    elseif ratio < 0.9 then
        monitor.setBackgroundColor(colors.orange)
    else
        monitor.setBackgroundColor(colors.red)
    end

    -- Draw the filled part
    monitor.setCursorPos(2, yPos)
    for i = 1, filledLength do
        monitor.write(" ")
    end

    -- Draw the unfilled part (in gray)
    monitor.setBackgroundColor(colors.gray)
    for i = filledLength + 1, width do
        monitor.write(" ")
    end
    
    -- Reset background color
    monitor.setBackgroundColor(colors.black)
end

-- Function to display storage information (centered)
local function displayStorageDetails(title, used, total, yPos)
    local w, _ = monitor.getSize()
    
    -- Display the title (centered)
    monitor.setTextColor(colors.blue)
    centerText(title, yPos)

    -- Draw the progress bar under the title
    drawProgressBar(used, total, w - 4, yPos + 1) -- Bar below the title
    
    -- Display the used / total storage (centered)
    local storageText = formatNumber(used) .. " / " .. formatNumber(total)
    monitor.setTextColor(colors.green)
    centerText(storageText, yPos + 3)

    -- Display the free space (centered)
    local freeSpaceText = "Free: " .. formatNumber(total - used)
    monitor.setTextColor(colors.lightGray)
    centerText(freeSpaceText, yPos + 4)
end

-- Main function to display all storage information
local function displayStorage()
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

    -- Clear the monitor
    monitor.clear()

    -- Display items storage info
    displayStorageDetails("Items", usedItemStorage, totalItemStorage, 2)

    -- Display fluids storage info (below the items section)
    displayStorageDetails("Fluids", usedFluidStorage, totalFluidStorage, 8)
end

-- Main loop to update the display
while true do
    displayStorage()
    sleep(5) -- Update every 5 seconds
end
