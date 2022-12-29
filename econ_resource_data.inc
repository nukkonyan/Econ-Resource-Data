#if defined _econ_resource_data_included
	#error Econ Resource Data is already included.
	#endinput
#endif

#define _econ_resource_data_included

/**
 *	Localize and translate the token string to its appropriate language string.
 *
 *	@param	client	The users index.
 *	@param	token	The token string to read and translate.
 *	@param	output	The output string.
 *	@param	maxlen	The maximum length of the output string.
 *
 *	@return	If failed to find token, this returns false.
 */
native bool EconResData_LocalizeToken(int client, const char[] token, char[] output, int maxlen);

/**
 *	Get the hex colour from token string.
 *
 *	@param	token	The token string to read.
 *
 *	@noreturn
 */
native int EconResData_GetColour(const char[] token);

/**
 *	Returns the item name by the clients language.
 *
 *	@param	client	The users index.
 *	@param	itemdef	The item definition index.
 *	@param	name	The item name output.
 *	@param	maxlen	The maximum length of the item name output.
 *
 *	@return	Returns if the item name was found or not.
 */
native bool EconResData_GetItemName(int client, int itemdef, char[] name, int maxlen);

/**
 *	Returns the keyvalue handle of the items_game.txt file.
 */
native KeyValues EconResData_GetKeyValues();

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
	MarkNativeAsOptional("EconResdata_GetKeyValues");
	
}
#endif