-- The locale for the Chinese language, provided generously by cikichen.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "zhCN")
if not L then return end

-- Option menu strings.
L["Rare window scale"] = "稀有窗口缩放"
L["Set the scale of the rare window."] = "设定稀有窗口缩放。"
L["Disable All"] = "禁用全部"
L["Disable all non-favorite rares in the list."] = "禁用全部非偏好稀有列表。"
L["Enable All"] = "启用全部"
L["Enable all rares in the list."] = "启用全部稀有列表。"
L["Reset Favorites"] = "重置偏好"
L["Reset the list of favorite rares."] = "重置偏好稀有列表。"
L["General Options"] = "通用选项"
L["Rare List Options"] = "偏好列表选项"
L["Active Rares"] = "激活稀有"

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "左键：隐藏/显示 RT"
L["Right-click: show options"] = "右键：显示选项"

-- Chat messages.
L["<RT> %s has died"] = "<RT> %s 已经挂了"
L["<RT> %s (%s%%)"] = "<RT> %s (%s%%)"
L["<RT> %s (%s%%) seen at ~(%.2f, %.2f)"] = "<RT> %s (%s%%) 发现了 ~(%.2f, %.2f)"
L["<RT> %s was last seen ~%s minutes ago"] = "<RT> %s 上次刷新在 ~%s 分钟以前"
L["<RT> %s seen alive, vignette at ~(%.2f, %.2f)"] = "<RT> %s 还活着, 坐标点在 ~(%.2f, %.2f)"
L["<RT> %s seen alive (combat log)"] = "<RT> %s 还活着（战斗记录）"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "点击方块，将稀有添加到你的偏好中。"
L["Click on the squares to announce rare timers."] = "点击方块，通报稀有的计时。"
L["Left click: report to general chat"] = "左键点击：通报到综合频道"
L["Control-left click: report to party/raid chat"] = "Ctrl-左键：通报到队伍/团队频道"
L["Alt-left click: report to say"] = "Alt-左键：通报到说"
L["Right click: set waypoint if available"] = "右键：如果可用则设置导航点"
L["Reset your data and replace it with the data of others."] = "重置您的数据并将其替换为其他人的数据。"
L["Note: you do not need to press this button to receive new timers."] = "注意：您无需按此按钮即可接收新的计时器。"

-- Rare frame strings.
L["Shard ID: %s"] = "共享 ID: %s"
L["Unknown"] = "未知"

-- Status messages.
L["<RT> Resetting current rare timers and requesting up-to-date data."] = "<RT> 重置当前稀有的计时器并请求最新数据。"
L["<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<RT> 重置之前请选中一个非玩家目标，这样插件可用确定当前的共享 ID。"
L["<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<RT> 重置按钮处于冷却状态。请注意，如果您打算重置数据，接收新的计时器不需要重置，请使用 /reload 然后再次点击重置按钮。"
L["<RT> Failed to register AddonPrefix '%s'. %s will not function properly."] = "<RT> 无法注册插件前缀 '%s'。%s无法正常运行。"
L["<RT> Moving to shard "] = "<RT> 移动到分片 "
L["<RT> Removing cached data for shard "] = "<RT> 删除分片缓存数据 "
L["<RT> Restoring data from previous session in shard "] = "<RT> 恢复上一个分片会话数据 "
L["<RT> Requesting rare kill data for shard "] = "<RT> 从分片请求稀有的击杀数据 "
L["<RT> Resetting ordering"] = "<RT> 正在重置排序"
L["<RT> Updating daily kill marks."] = "<RT> 正在更新日常击杀标记。"
L["<RT> Your version of the %s addon is outdated. Please update to the most recent version at the earliest convenience."] = "<RT> 版本 %s 插件已过期。请尽快将其更新为最新版本。"

-- Option menu strings.
L["Favorite sound alert"] = "偏好警报声"
L["Show minimap icon"] = "显示小地图图标"
L["Enable debug mode"] = "启用除错模式"
L["Show RT debug output in the chat."] = "在聊天中显示 RT 除错输出。"
L["Show/hide the RT minimap icon."] = "显示/隐藏 RT 小地图图标。"
L["Enable communication over party/raid channel"] = "启用通过队伍/团队频道的通信"
L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = "启用通过队伍/团队频道的通信，以在队伍或团队中提供跨服区域功能。"