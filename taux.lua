-- Initialize peripherals and variables
local monitor = peripheral.find("monitor")
local rsBridge = peripheral.find("rsBridge")
local previousItemCount = 0

-- Set monitor scale and clear
monitor.setTextScale(5)  -- Very large text
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
    local w, _ = monitor.getSize()
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- Function to calculate and display items added per minute
local function displayItemsAddedPerMinute()
    -- Get the current number of items in the system
    local currentItemCount = 0
    for _, item in pairs(rsBridge.listItems()) do
        currentItemCount = currentItemCount + item.amount
    end
    
    -- Calculate the number of items added in the last minute
    local itemsAdded = currentItemCount - previousItemCount
    previousItemCount = currentItemCount -- Update the previous count

    -- Format the number
    local formattedItemsAdded = formatNumber(itemsAdded)

    -- Choose the background color based on the number of items added
    if itemsAdded < 1000 then
        monitor.setBackgroundColor(colors.green)
    elseif itemsAdded < 10000 then
        monitor.setBackgroundColor(colors.yellow)
    elseif itemsAdded < 100000 then
        monitor.setBackgroundColor(colors.orange)
    else
        monitor.setBackgroundColor(colors.red)
    end

    -- Set text color to white
    monitor.setTextColor(colors.white)

    -- Clear the monitor with the selected background color
    monitor.clear()

    -- Display the centered number
    centerText(formattedItemsAdded, math.floor(monitor.getSize() / 2))
end

-- Main loop to update the display every minute
while true do
    displayItemsAddedPerMinute()
    sleep(60) -- Wait 60 seconds (1 minute) before updating again
end
