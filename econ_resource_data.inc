#if defined _econ_resource_data_included
	#error Econ Resource Data is already included.
	#endinput
#endif

#define _econ_resource_data_included

/**
 * Called when the items_game.txt has been parsed.
 *
 * @param	kv	The items_game.txt keyvalues.
 *
 * @noreturn
 */
forward void EconResData_OnItemsGameLoaded(KeyValues kv);

/**
 *	Localize and translate the token string to its appropriate language string.
 *
 * @param	client	The users index.
 * @param	token	The token string to read and translate.
 * @param	output	The output string.
 * @param	maxlen	The maximum length of the output string.
 *
 * @return	If failed to find token, this returns false.
 */
native bool EconResData_LocalizeToken(int client, const char[] token, char[] output, int maxlen);

/**
 * Get the hex colour from token string.
 *
 * @param	token	The token string to read.
 *
 * @noreturn
 */
native int EconResData_GetColour(const char[] token);

/**
 * Returns the item name by the clients language.
 *
 * @param	client	The users index.
 * @param	itemdef	The item definition index.
 * @param	name	The item name output.
 * @param	maxlen	The maximum length of the item name output.
 *
 * @return	Returns if the item name was found or not.
 */
native bool EconResData_GetItemName(int client, int itemdef, char[] name, int maxlen);

/**
 * Returns the item classname.
 *
 * @param	itemdef		The item definition index to read.
 * @param	classname	The buffer to store the classname we've just retrieved.
 * @param	maxlen		The maximum length of the classname output.
 *
 * @return	Returns if the item classname was found or not.
 */
native bool EconResData_GetItemClassname(int itemdef, char[] classname, int maxlen);

/**
 * Returns wheter the item classname is valid.
 *
 * @param	classname	The item classname.
 *
 * @return	Returns wheter the classname is valid or not.
 */
native bool EconResData_ValidItemClassname(const char[] item_classname);

/**
 * Returns the keyvalue handle of the items_game.txt file.
 *
 * Must be destroyed after use to prevent memory leak.
 */
native KeyValues EconResData_GetKeyValues();

/**
 * Returns an array list of game skins.
 *
 * Must be destroyed after use to prevent memory leak.
 */
native ArrayList EconResData_GetGameSkins();

/**
 * Returns the game's classnames.
 *
 * Must be destroyed after use to prevent memory leak.
 */
native ArrayList EconResData_GetGameClassnames();

/**
 * Returns if the skin id is valid.
 *
 * @param	skin_id		The skin's defined id.
 *
 * @error	If game contains no skins, this returns false.
 */
native bool EconResData_ValidGameSkin(int skin_id);

/**
 * Returns the game's graffitis.
 * This is CS:GO only.
 *
 * Must be destroyed after use to prevent memory leak.
 */
native ArrayList EconResData_GetGameGraffitis();

/**
 * Returns if the graffiti id is valid.
 * This is CS:GO only.
 *
 * @param	graffiti_id		The graffiti's defined item id.
 *
 * @error	If game contains no graffitis, this returns false.
 */
native bool EconResData_ValidGameGraffiti(int graffiti_id);

public SharedPlugin __pl_econ_resource_data = {
	name = "EconResourceData",
	file = "econ_resource_data.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
}

#if !defined REQUIRE_PLUGIN
public void __pl_econ_resource_data_SetNTVOptional() {
	MarkNativeAsOptional("EconResData_LocalizeToken");
	MarkNativeAsOptional("EconResData_GetColour");
	MarkNativeAsOptional("EconResData_GetItemName");
	MarkNativeAsOptional("EconResData_GetItemClassname");
	MarkNativeAsOptional("EconResData_ValidItemClassname");
	MarkNativeAsOptional("EconResData_GetKeyValues");
	MarkNativeAsOptional("EconResData_GetGameSkins");
	MarkNativeAsOptional("EconResData_GetGameClassnames");
	MarkNativeAsOptional("EconResData_ValidGameSkin");
	MarkNativeAsOptional("EconResData_GetGameGraffitis");
	MarkNativeAsOptional("EconResData_ValidGameGraffiti");
}
#endif