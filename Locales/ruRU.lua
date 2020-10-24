-- The locale for the Russian language, provided generously by dak1ne-4th.
local L = LibStub("AceLocale-3.0"):NewLocale("RareTracker", "ruRU")
if not L then return end

-- Addon icon instructions.
L["Left-click: hide/show RT"] = "Левый клик: скрыть/показать таблицу"
L["Right-click: show options"] = "Правый клик: показать настройки"

-- Chat messages.
L["<%s> %s has died"] = "<%s> %s был убит"
L["<%s> %s (%s%%)"] = "<%s> %s (%s%%)"
L["<%s> %s (%s%%) seen at ~(%.2f, %.2f)"] = "<%s> %s (%s%%), координаты ~(%.2f, %.2f)"
L["<%s> %s was last seen ~%s minutes ago"] = "<%s> %s, был убит ~%s мин. назад"
L["<%s> %s seen alive, vignette at ~(%.2f, %.2f)"] = "<%s> %s в последний раз был замечен ~(%.2f, %.2f)"
L["<%s> %s seen alive (combat log)"] = "<%s> %s был замечен (на основании данных лога)"

-- Rare frame instructions.
L["Click on the squares to add rares to your favorites."] = "Кликните по квадратам, что бы добавить в список избранных."
L["Click on the squares to announce rare timers."] = "Кликните по квадратам, что бы анонсировать таймеры."
L["Left click: report to general chat"] = "Левый клик: сообщить в общий чат"
L["Control-left click: report to party/raid chat"] = "Ctrl+Левый клик: сообщить в групповой/рейдовый чат"
L["Alt-left click: report to say"] = "Alt+Левый клик: сообщить в канал 'сказать'"
L["Right click: set waypoint if available"] = "Правый клик: добавить маршрутную точку, если возможно"
L["Reset your data and replace it with the data of others."] = "Сбросить свои данные и заменить их полученными от других данными."
L["Note: you do not need to press this button to receive new timers."] = "Важно: Вам НЕ нужно нажимать эту кнопку, что бы обновить таймеры."

-- Rare frame strings.
L["Shard ID: %s"] = "ID сервера/слоя: %s"
L["Unknown"] = "Неизвестно"

-- Status messages.
L["<%s> Resetting current rare timers and requesting up-to-date data."] = "<%s> Сброс текущих таймеров рарников и запрос актуальных данных."
L["<%s> Please target a non-player entity prior to resetting, such that the addon can determine the current shard id."] = "<%s> Выберите НПЦ, что бы аддон смог определить ID сервера/слоя."
L["<%s> The reset button is on cooldown. Please note that a reset is not needed to receive new timers. If it is your intention to reset the data, please do a /reload and click the reset button again."] = "<%s> Процедура сброса все еще восстанавливается. Имейте в виду, сброс НЕ нужен для получения новых таймеров. Если все же, Вам необходимо сбросить данные, то перезагрузите интерфейс используя /reload и нажмите кнопку сброса повторно."
L["<%s> Failed to register AddonPrefix '%s'. %s will not function properly."] = "<%s> Не удалось загрузить '%s'. %s не будет функционировать корректно."
L["<%s> Moving to shard "] = "<%s> Перемещаемся на сервер/слой "
L["<%s> Removing cached data for shard "] = "<%s> Удаляем кэш сервера/слоя "
L["<%s> Restoring data from previous session in shard "] = "<%s> Восстанавливаем данные прошлых сессий сервера/слоя "
L["<%s> Requesting rare kill data for shard "] = "<%s> Запрашиваем данные убийств рарников для сервера/слоя "
L["<%s> Resetting ordering"] = "<%s> Сбрасываем очередность"
L["<%s> Updating daily kill marks."] = "<%s> Обновляем ежедневные цели."
L["<%s> Your version of the %s addon is outdated. Please update to the most recent version at the earliest convenience."] = "<%s> Ваша версия %s устарела. Обновите до актуальной версии при ближайшей возмозможности."

-- Option menu strings.
L["Favorite sound alert"] = "Звуковой сигнал для избранных"
L["Show minimap icon"] = "Показывать иконку у мини-карты"
L["Enable debug mode"] = "Включить режим отладки"
L["Show RT debug output in the chat."] = "Показывать данные отладки в чате."
L["Show/hide the RT minimap icon."] = "Показать/скрыть иконку аддона RT у мини-карты."
L["Enable communication over party/raid channel"] = "Включить коммуникации через групповой/рейдовый чаты"
L["Enable communication over party/raid channel, to provide CRZ functionality while in a party or raid group."] = "Включить коммуникации через групповой/рейдовый чаты, что бы CRZ функционировало пока Вы находитесь в группе/рейде."