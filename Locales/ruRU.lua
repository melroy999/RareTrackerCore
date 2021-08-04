-- The locale for the Russian language, provided generously by dak1ne-4th.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "ruRU")
if not L then return end

-- Status messages.
-- L["<RT> The rare window cannot be shown, since the current zone is not covered by any of the zone modules."] = ""
L["<RT> Your version of the RareTracker addon is outdated. Please update to the most recent version at the earliest convenience."] = "<RTC> Ваша версия RareTracker устарела. Обновите до актуальной версии при ближайшей возмозможности."
L["<RT> Resetting current rare timers and requesting up-to-date data."] = "<RTC> Сброс текущих таймеров рарников и запрос актуальных данных."
L["<RT> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<RTC> Выберите НПЦ, что бы аддон смог определить ID сервера/слоя."
L["<RT> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<RTC> Процедура сброса все еще восстанавливается. Имейте в виду, сброс НЕ нужен для получения новых таймеров. Если все же, Вам необходимо сбросить данные, то перезагрузите интерфейс используя /reload и нажмите кнопку сброса повторно."
L["<RT> Moving to shard "] = "<RTC> Перемещаемся на сервер/слой "

-- Chat messages.
L["<RT> %s has died"] = "<RTC> %s был убит"
L["<RT> %s (%s%%)"] = "<RTC> %s (%s%%)"
L["<RT> %s (%s%%) seen at %s"] = "<RTC> %s (%s%%), координаты %s"
L["<RT> %s was last seen ~%s minutes ago"] = "<RTC> %s, был убит ~%s мин. назад"
L["<RT> %s seen alive, vignette at %s"] = "<RTC> %s в последний раз был замечен %s"
L["<RT> %s seen alive (combat log)"] = "<RTC> %s был замечен (на основании данных лога)"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "Кликните по квадратам, что бы добавить в список избранных."
L["Click on the squares to announce rare timers."] = "Кликните по квадратам, что бы анонсировать таймеры."
L["Left click: report to general chat"] = "Левый клик: сообщить в общий чат"
L["Control-left click: report to party/raid chat"] = "Ctrl+Левый клик: сообщить в групповой/рейдовый чат"
L["Alt-left click: report to say"] = "Alt+Левый клик: сообщить в канал 'сказать'"
L["Right click: set waypoint if available"] = "Правый клик: добавить маршрутную точку, если возможно"
L["Reset your data and replace it with the data of others."] = "Сбросить свои данные и заменить их полученными от других данными."
L["Note: you do not need to press this button to receive new timers."] = "Важно: Вам НЕ нужно нажимать эту кнопку, что бы обновить таймеры."

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "Левый клик: скрыть/показать таблицу"
L["Right-click: show options"] = "Правый клик: показать настройки"

-- Option menu strings.
L["Favorite sound alert"] = "Звуковой сигнал для избранных"
L["Show/hide the RT minimap icon."] = "Показать/скрыть иконку аддона RT у мини-карты."
L["Enable communication over party/raid channel"] = "Включить коммуникации через групповой/рейдовый чаты"
L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = "Включить коммуникации через групповой/рейдовый чаты, что бы CRZ функционировало пока Вы находитесь в группе/рейде."
L["Enable debug mode"] = "Включить режим отладки"
L["Show RT debug output in the chat."] = "Показывать данные отладки в чате."
L["Rare window scale"] = "Масштаб окна с рарниками"
L["Set the scale of the rare window."] = "Определите масштаб окна с рарниками."
L["Disable All"] = "Отключить всех"
L["Disable all non-favorite rares in the list."] = "Отключить всех не включенных в список фаворитов рарников."
L["Enable All"] = "Включить всех"
L["Enable all rares in the list."] = "Включить всех рарников из листа."
L["Reset Favorites"] = "Сбросить фаворитов"
L["Reset the list of favorite rares."] = "Сбросить список фаворитов рарников."
L["Active Rares"] = "Активные рарнинки"
L["Show minimap icon"] = "Показывать иконку у мини-карты"
-- L["Shared Options"] = ""
-- L["General"] = ""

-- Rare frame strings.
L["Shard ID: %s"] = "ID сервера/слоя: %s"
L["Unknown"] = "Неизвестно"