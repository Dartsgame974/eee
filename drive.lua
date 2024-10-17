-- Load AUKit for audio playback
local aukit = require("aukit")
local speaker = peripheral.find("speaker") -- Automatically finds the connected speaker
local mf = require("morefonts") -- Load More Fonts library

-- Find monitors automatically
local monitorLeft = peripheral.find("monitor", function(name, mon) return mon.getSize() == (w, h) and w > h end) -- Assuming left is taller
local monitorRight = peripheral.find("monitor", function(name, mon) return mon.getSize() == (w, h) and w > h end) -- Assuming right is taller
local monitorAlert = peripheral.find("monitor", function(name, mon) return mon.getSize() == (w, h) and h >= w end) -- Assuming alert monitor is central

-- Ensure all monitors were found, else display an error
if not monitorLeft or not monitorRight or not monitorAlert then
    print("Error: One or more monitors not found!")
    return
end

-- Set monitor scales
monitorLeft.setTextScale(1)
monitorRight.setTextScale(1)
monitorAlert.setTextScale(1)

-- Function to format numbers into K (thousand), M (million), etc.
local function formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Function to draw a vertical progress bar
local function drawVerticalBar(monitor, used, total, width, height, barColor, yPos)
    local ratio = used / total
    local filledHeight = math.floor(ratio * height)

    -- Draw the vertical progress bar
    for y = 1, height do
        monitor.setCursorPos(width, yPos + height - y)
        if y <= filledHeight then
            monitor.setBackgroundColor(barColor) -- Filled bar section
        else
            monitor.setBackgroundColor(colors.gray) -- Empty bar section
        end
        monitor.write(" ") -- Writing a "square" for each vertical section
    end

    -- Reset background color
    monitor.setBackgroundColor(colors.black)
end

-- Function to display storage usage on the vertical bars
local function displayStorageUsage(monitorLeft, monitorRight)
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

    -- Clear monitors
    monitorLeft.clear()
    monitorRight.clear()

    -- Display vertical bars on left (item storage) and right (fluid storage)
    local widthLeft, heightLeft = monitorLeft.getSize()
    local widthRight, heightRight = monitorRight.getSize()

    -- Draw the green vertical progress bar for item storage
    drawVerticalBar(monitorLeft, usedItemStorage, totalItemStorage, widthLeft // 2, heightLeft, colors.green, 2)
    
    -- Draw the blue vertical progress bar for fluid storage
    drawVerticalBar(monitorRight, usedFluidStorage, totalFluidStorage, widthRight // 2, heightRight, colors.blue, 2)
end

-- Function to display alert messages on monitorAlert
local function displayAlert()
    -- Get storage status
    local totalItemStorage = rsBridge.getMaxItemDiskStorage()
    local usedItemStorage = 0
    for _, item in pairs(rsBridge.listItems()) do
        usedItemStorage = usedItemStorage + item.amount
    end
    local freeItemStorage = totalItemStorage - usedItemStorage

    local totalFluidStorage = rsBridge.getMaxFluidDiskStorage()
    local usedFluidStorage = 0
    for _, fluid in pairs(rsBridge.listFluids()) do
        usedFluidStorage = usedFluidStorage + fluid.amount
    end
    local freeFluidStorage = totalFluidStorage - usedFluidStorage

    -- Clear monitorAlert
    monitorAlert.clear()

    -- Determine which message to display
    if freeItemStorage <= 10000 and freeFluidStorage <= 10000 then
        -- Display both alerts (items and fluids)
        monitorAlert.setCursorPos(1, 2)
        monitorAlert.setTextColor(colors.red)
        mf.writeOn(monitorAlert, "STOCKAGE COMPLET!!!", nil, 2, {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })
        sleep(2)
        monitorAlert.clear()
        mf.writeOn(monitorAlert, "FLUID COMPLET!!!", nil, 2, {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })
        sleep(2)
    elseif freeItemStorage <= 10000 then
        -- Display only item storage alert
        monitorAlert.setCursorPos(1, 2)
        monitorAlert.setTextColor(colors.red)
        mf.writeOn(monitorAlert, "STOCKAGE COMPLET!!!", nil, 2, {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })
        sleep(2)
    elseif freeFluidStorage <= 10000 then
        -- Display only fluid storage alert
        monitorAlert.setCursorPos(1, 2)
        monitorAlert.setTextColor(colors.red)
        mf.writeOn(monitorAlert, "FLUID COMPLET!!!", nil, 2, {
            font = "fonts/PublicPixel",
            scale = 0.5,
            anchorHor = "center",
        })
        sleep(2)
    end
end

-- Function to monitor and update displays
local function monitorStorage()
    while true do
        -- Display vertical storage bars on left and right monitors
        displayStorageUsage(monitorLeft, monitorRight)
        
        -- Check if we need to display alert on monitor_0
        local totalItemStorage = rsBridge.getMaxItemDiskStorage()
        local usedItemStorage = 0
        for _, item in pairs(rsBridge.listItems()) do
            usedItemStorage = usedItemStorage + item.amount
        end
        local freeItemStorage = totalItemStorage - usedItemStorage

        local totalFluidStorage = rsBridge.getMaxFluidDiskStorage()
        local usedFluidStorage = 0
        for _, fluid in pairs(rsBridge.listFluids()) do
            usedFluidStorage = usedFluidStorage + fluid.amount
        end
        local freeFluidStorage = totalFluidStorage - usedFluidStorage

        if freeItemStorage <= 10000 or freeFluidStorage <= 10000 then
            -- Play alert sound and display alerts
            aukit.play(aukit.stream.wav(io.lines("alert.wav", 48000)), speaker)
            displayAlert()
        end

        -- Update every 5 seconds
        sleep(5)
    end
end

-- Run the monitoring function
monitorStorage()
