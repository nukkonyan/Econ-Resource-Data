> # Econ Resource Data v1.0.8
Localize and translate strings from within the game.

> # Natives
  - `EconResData_LocalizeToken(int client, const char[] token, char[] output, int maxlen)`
  - `EconResData_GetColour(const char[] token)`
  - `EconResData_GetItemName(int client, int itemdef, char[] name, int maxlen)`
  - `EconResData_ValidItemClassname(const char[] item_classname)`
  - `EconResData_GetKeyValues()`
  - `EconResData_GetGameSkins()`
  - `EconResData_GetGameClassnames()`
  - `EconResData_ValidGameSkin(int skin_id)`

> # Todo
  - Fix CS:GO tokens to be read properly from the language file, as some fails to be read due to special characters.
     - such as `：` and other language-specific characters such as from japanese, which hinders from reading further through the language file.

> # Credits
  - Credits to [Dr. McKay](https://github.com/DoctorMcKay) for the language file parsing code, loaning from Enhanced Item Notifications plugin
  - Credits to [dragokas](https://github.com/dragokas) for some fixes regarding parsing the language file.
  - Check out ['Enhanced Item Notifications'](https://github.com/DoctorMcKay/sourcemod-plugins/blob/918ff5d60b56b0cc04915b611b7fc1e61c2ca25b/scripting/enhanced_items.sp) made by legendary Dr. McKay.
