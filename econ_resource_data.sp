#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

/*
 * Credits to legendary Dr. McKay for the language file parsing code, loaning from enhanced_items.sp (Enhanced Item Notifications) plugin
 * Credits to dragokas for some fixes.
 * Check 'Enhanced Item Notifications' made by legendary Dr. McKay.
 */

public Plugin myinfo =
{
	name = "Econ Resource Data",
	author = "nukkonyan",
	description = "Localize tokens and translation strings.",
	version = "1.1.1",
	url = "https://github.com/nukkonyan"
}

#define items_game_txt "scripts/items/items_game.txt"
#define clientscheme_res "resource/clientscheme.res"
char folder_name[16];

enum struct ResourceInfo
{
	int language;
	char token[96];
	char value[1024];
}

enum struct ItemsGameRes
{
	KeyValues Schema;
	StringMap Languages;
	ArrayList LanguagesBackup;
	StringMap Colours;
	ArrayList Classnames;
	ArrayList Skins;
	StringMap ClassnamesPrefab;
	ArrayList Graffitis;
	
	void Load()
	{
		this.Schema = new KeyValues("items_game");
		if(this.Schema.ImportFromFile(items_game_txt))
		{
			CallSchemaForward();
		}
		
		this.Languages = new StringMap();
		this.LanguagesBackup = new ArrayList(sizeof(ResourceInfo));
		this.Colours = new StringMap();
		this.Classnames = new ArrayList(16);
		this.ClassnamesPrefab = new StringMap();
		
		switch(GetEngineVersion())
		{
			case Engine_TF2:
			{
				if(StrEqual(folder_name, "tf", false))
				{
					this.Skins = new ArrayList();
				}
			}
			case Engine_CSGO:
			{
				this.Skins = new ArrayList();
				this.Graffitis = new ArrayList();
			}
		}
		
		KeyValues kv = new KeyValues("Scheme");
		kv.ImportFromFile(clientscheme_res);
		
		if(kv.JumpToKey("Colors"))
		{
			kv.GotoFirstSubKey(false);
			
			do
			{
				char name[32];
				kv.GetSectionName(name, sizeof(name));
				
				int r, g, b, colour;
				kv.GetColor(NULL_STRING, r, g, b, colour);
				colour = (r << 16) | (g << 8) | (b << 0);
				
				StrToLower(name);
				
				this.Colours.SetValue(name, colour);
			}
			while(kv.GotoNextKey(false));
			
			kv.GoBack();
		}
		
		if(kv.JumpToKey("BaseSettings"))
		{
			kv.GotoFirstSubKey(false);
			
			do
			{
				char name[32];
				kv.GetSectionName(name, sizeof(name));
				
				int r, g, b, colour;
				kv.GetColor(NULL_STRING, r, g, b, colour);
				colour = (r << 16) | (g << 8) | (b << 0);
				
				StrToLower(name);
				
				this.Colours.SetValue(name, colour);
			}
			while(kv.GotoNextKey(false));
		}
		
		delete kv;
		
		this.GetClassnames();
		this.GetSkins();
		this.GetGraffitis();
	}
	
	bool LocalizeToken(int client, const char[] token, char[] output, int maxlen)
	{
		StringMap lang = this.GetLanguage(client);
		if(lang == null)
		{
			LogError("Unable to localize token '%s' for server language!", token);
			return false;
		}
		
		char fallback[128];
		bool rtrn = lang.GetString(token, fallback, sizeof(fallback));
		
		// Some tokens just fails to be read even though it's stored.
		if(!rtrn)
		{
			int index = -1, language = (client == LANG_SERVER) ? GetServerLanguage() : GetClientLanguage(client);
			
			if((index = this.LanguagesBackup.FindValue(language)) >= 0)
			{
				ResourceInfo info;
				this.LanguagesBackup.GetArray(index, info, sizeof(info));
				
				if(StrEqual(fallback[1], info.token, false))
				{
					strcopy(fallback, sizeof(fallback), info.value);
					rtrn = true;
				}
			}
		}
		
		strcopy(output, maxlen, fallback);
		return rtrn;
	}
	
	bool GetItemName(int client, int itemdef, char[] name, int maxlen)
	{
		switch(GetEngineVersion())
		{
			case Engine_TF2:
			{
				char index[24];
				IntToString(itemdef, index, sizeof(index));
				
				this.Schema.Rewind();
				this.Schema.JumpToKey("items");
				
				if(!this.Schema.JumpToKey(index))
				{
					return false;
				}
				
				char item_name[128];
				this.Schema.GetString("item_name", item_name, sizeof(item_name));
				
				if(strlen(item_name) < 1)
				{
					char prefab[64];
					this.Schema.GetString("prefab", prefab, sizeof(prefab));
					
					if(strlen(prefab) < 1)
					{
						return false;
					}
					
					char armory_desc[32];
					this.Schema.GetString("armory_desc", armory_desc, sizeof(armory_desc));
					
					bool baseitem = (StrContainsEx(armory_desc, "stockitem") || (this.Schema.GetNum("baseitem", -1) == 1));
					
					this.Schema.Rewind();
					this.Schema.JumpToKey("prefabs");
					
					char buffer[3][64];
					ExplodeString(prefab, " ", buffer, sizeof(buffer), sizeof(prefab));
					
					for(int i = 0; i < sizeof(buffer); i++)
					{
						if(this.Schema.JumpToKey(buffer[i]))
						{
							this.Schema.GetString("item_name", item_name, sizeof(item_name));
							if(baseitem)
							{
								this.Schema.SetNum("propername", 1);
							}
							break;
						}
					}
					
					if(strlen(item_name) < 1)
					{
						return false;
					}
				}
				
				StringMap lang = this.GetLanguage(client); //No memory leak to be worried about, since we don't clone it.
				if(lang == null)
				{
					LogError("Unable to get item name for server language (attempting to print to \"%L\")!", client);
					return false;
				}
				
				if(!this.LocalizeToken(client, item_name[1], name, maxlen))
				{
					return false;
				}
				
				char language_name[32];
				lang.GetString("__name__", language_name, sizeof(language_name));
				if(StrEqual(language_name, "english") && this.Schema.GetNum("propername"))
				{
					Format(name, maxlen, "The %s", name);
				}
				
				return true;
			}
			
			case Engine_CSGO:
			{
				char index[24];
				IntToString(itemdef, index, sizeof(index));
				
				this.Schema.Rewind();
				this.Schema.JumpToKey("items");
				
				if(!this.Schema.JumpToKey(index))
				{
					return false;
				}
				
				char item_name[128];
				this.Schema.GetString("item_name", item_name, sizeof(item_name));
				
				if(strlen(item_name) < 1)
				{
					char prefab[64];
					this.Schema.GetString("prefab", prefab, sizeof(prefab));
					
					if(strlen(prefab) < 1)
					{
						return false;
					}
					
					this.Schema.Rewind();
					this.Schema.JumpToKey("prefabs");
					
					char buffer[3][64];
					ExplodeString(prefab, " ", buffer, sizeof(buffer), sizeof(prefab));
					
					for(int i = 0; i < sizeof(buffer); i++)
					{
						if(this.Schema.JumpToKey(buffer[i]))
						{
							this.Schema.GetString("item_name", item_name, sizeof(item_name));
							break;
						}
					}
					
					if(strlen(item_name) < 1)
					{
						return false;
					}
					
					StringMap lang = this.GetLanguage(client);
					if(lang == null)
					{
						LogError("Unable to get item name for server language (attempting to print to \"%L\")!", client);
						return false;
					}
					
					return this.LocalizeToken(client, item_name[1], name, maxlen);
				}
			}
		}
		
		return false;
	}
	
	bool GetItemClassname(int itemdef, char[] classname, int maxlen)
	{
		switch(GetEngineVersion())
		{
			case Engine_TF2:
			{
				// to be added
			}
			
			case Engine_CSGO:
			{
				char str_itemdef[11];
				IntToString(itemdef, str_itemdef, sizeof(str_itemdef));
				
				this.Schema.Rewind();
				this.Schema.JumpToKey("items");
				
				if(this.Schema.JumpToKey(str_itemdef))
				{
					this.Schema.GetString("name", classname, maxlen);
				}
			}
		}
		
		return false;
	}
	
	StringMap GetLanguage(int client)
	{
		int language = (client == LANG_SERVER) ? GetServerLanguage() : GetClientLanguage(client);
		
		char language_name[64];
		GetLanguageInfo(language, _, _, language_name, sizeof(language_name));
		
		StringMap lang;
		if(!this.Languages.GetValue(language_name, lang))
		{
			lang = this.ParseLanguage(language_name, language);
			this.Languages.SetValue(language_name, lang);
		}
		
		if(lang == null && client != LANG_SERVER)
		{
			return this.GetLanguage(LANG_SERVER);
		}
		//else if(lang == null) return null;
		
		return lang;
	}
	
	StringMap ParseLanguage(const char[] language_name, int language)
	{
		char filename[64];
		Format(filename, sizeof(filename), "resource/%s_%s.txt", folder_name, language_name);
		
		File file;
		if((file = OpenFile(filename, "r")) == null)
		{
			return null;
		}
		
		StringMap lang = new StringMap();
		lang.SetString("__name__", language_name);
		
		int data, i = 0, high_surrogate, low_surrogate;
		char line[4096];
		while(ReadFileCell(file, data, 2) == 1)
		{
			if(high_surrogate)
			{
				// for characters in range 0x10000 <= X <= 0x10FFFF
				low_surrogate = data;
				data = ((high_surrogate - 0xD800) << 10) + (low_surrogate - 0xDC00) + 0x10000;
				line[i++] = ((data >> 18) & 0x07) | 0xF0;
				line[i++] = ((data >> 12) & 0x3F) | 0x80;
				line[i++] = ((data >> 6) & 0x3F) | 0x80;
				line[i++] = (data & 0x3F) | 0x80;
				high_surrogate = 0;
			}
			else if(data < 0x80)
			{
				// It's a single-byte character
				line[i++] = data;
				
				if(data == '\n')
				{
					line[i] = '\0';
					this.HandleLangLine(line, lang, language);
					i = 0;
				}
			}
			else if(data < 0x800)
			{
				// It's a two-byte character
				line[i++] = ((data >> 6) & 0x1F) | 0xC0;
				line[i++] = (data & 0x3F) | 0x80;
			}
			/*
			else if(data < 0x8000)
			{
				// It's a three-byte character
				
				// code to be put in here
			}
			*/
			else if(data <= 0xFFFF)
			{
				if(0xD800 <= data <= 0xDFFF)
				{
					high_surrogate = data;
					continue;
				}
				
				line[i++] = ((data >> 12) & 0x0F) | 0xE0;
				line[i++] = ((data >> 6) & 0x3F) | 0x80;
				line[i++] = (data & 0x3F) | 0x80;
			}
		}
		
		delete file;
		return lang;
	}
	
	void HandleLangLine(char[] line, StringMap lang, int language) {
		TrimString(line);
		
		// Not a line containing at least one quoted string
		if(line[0] != '"') return;
		
		char token[96], value[1024];
		int pos = BreakString(line, token, sizeof(token));
		
		// This line doesn't have two quoted strings
		if(pos == -1) return;
		
		BreakString(line[pos], value, sizeof(value));
		lang.SetString(token, value);
		
		// StringMap() limitation.
		ResourceInfo info;
		info.language = language;
		info.token = token;
		info.value = value;
		this.LanguagesBackup.PushArray(info);
	}
	
	void GetClassnames()
	{
		switch(GetEngineVersion())
		{
			case Engine_CSGO:
			{
				this.Schema.Rewind();
				
				if(this.Schema.JumpToKey("prefabs"))
				{
					if(this.Schema.GotoFirstSubKey())
					{
						do
						{
							char classname[64];
							
							this.Schema.GetString("item_class", classname, sizeof(classname));
							if(strlen(classname) > 0)
							{
								if(this.Classnames.FindString(classname) == -1)
								{
									this.Classnames.PushString(classname);
								}
							}
							
							this.Schema.GetString("anim_class", classname, sizeof(classname));
							if(strlen(classname) > 0)
							{
								if(this.Classnames.FindString(classname) == -1)
								{
									this.Classnames.PushString(classname);
								}
							}
						}
						while(this.Schema.GotoNextKey());
						
						this.Schema.GoBack();
					}
					
					this.Schema.GoBack();
				}
				
				if(this.Schema.JumpToKey("items"))
				{
					if(this.Schema.GotoFirstSubKey())
					{
						do
						{
							char classname[64];
							this.Schema.GetString("item_class", classname, sizeof(classname));
							
							if(strlen(classname) >= 1)
							{
								if(this.Classnames.FindString(classname) == -1)
								{
									this.Classnames.PushString(classname);
								}
							}
						}
						while(this.Schema.GotoNextKey());
					}
				}
			}
			
			case Engine_TF2:
			{
				if(!StrEqual(folder_name, "tf", false))
				{
					return;
				}
				
				if(!this.Schema.JumpToKey("prefabs"))
				{
					return;
				}
				
				if(this.Schema.GotoFirstSubKey())
				{
					do
					{
						char section[64], item_class[64];
						this.Schema.GetSectionName(section, sizeof(section));
						this.Schema.GetString("item_class", item_class, sizeof(item_class));
						
						// valid item classname
						if(strlen(item_class) > 0)
						{
							if(this.Classnames.FindString(item_class) == -1)
							{
								this.Classnames.PushString(item_class);
							}
						}
						
						// no item classname, must find prefab within
						else
						{
							char prefabs[96];
							this.Schema.GetString("prefab", prefabs, sizeof(prefabs));
							this.Schema.GoBack();
							
							char buffer1[4][64];
							int found1 = ExplodeString(prefabs, " ", buffer1, sizeof(buffer1), 64);
							
							for(int i = 0; i < found1; i++)
							{
								// found valid prefab within
								if(this.Schema.JumpToKey(buffer1[i]))
								{
									this.Schema.GetString("item_class", item_class, sizeof(item_class));
									this.Schema.GoBack();
									
									if(strlen(item_class) > 0)
									{
										if(this.Classnames.FindString(item_class) == -1)
										{
											this.Classnames.PushString(item_class);
										}
									}
									else
									{
										char buffer2[4][64];
										int found2 = ExplodeString(prefabs, " ", buffer2, sizeof(buffer2), 64);
										
										this.Schema.GetString("prefab", prefabs, sizeof(prefabs));
										
										for(int x = 0; x < found2; x++)
										{
											if(this.Schema.JumpToKey(buffer2[x]))
											{
												this.Schema.GetString("item_class", item_class, sizeof(item_class));
												this.Schema.GoBack();
												
												if(strlen(item_class) > 0)
												{
													if(this.Classnames.FindString(item_class) == -1)
													{
														this.Classnames.PushString(item_class);
													}
												}
											}
										}
									}
								}
							}
							
							this.Schema.JumpToKey(section);
						}
					}
					
					//delete prefabs;
					while(this.Schema.GotoNextKey());
				}
			}
		}
	}
	
	void GetSkins() {
		switch(GetEngineVersion()) {
			case Engine_CSGO: {
				this.Schema.Rewind();
				
				if(this.Schema.GotoFirstSubKey()) {
					do {
						char section[16];
						this.Schema.GetSectionName(section, sizeof(section));
						
						if(StrEqual(section, "paint_kits")) {
							if(this.Schema.GotoFirstSubKey()) {
								do {
									this.Schema.GetSectionName(section, sizeof(section));
									int paintkit_id = StringToInt(section);
									
									if(paintkit_id < 1 || paintkit_id == 9001) continue;
									if(this.Skins.FindValue(paintkit_id) == -1) this.Skins.Push(paintkit_id);
								}
								while(this.Schema.GotoNextKey());
								
								this.Schema.GoBack();
							}
						}
					}
					while(this.Schema.GotoNextKey());
				}
			}
			case Engine_TF2: {
				if(StrEqual(folder_name, "tf", false)) {
					this.Schema.Rewind();
					
					if(this.Schema.JumpToKey("items")) {
						if(this.Schema.GotoFirstSubKey()) {
							do {
								if(this.Schema.JumpToKey("static_attrs")) {
									int paintkit_proto_def_index = this.Schema.GetNum("paintkit_proto_def_index");
									if(this.Skins.FindValue(paintkit_proto_def_index) == -1) this.Skins.Push(paintkit_proto_def_index);
									this.Schema.GoBack();
								}
							}
							while(this.Schema.GotoNextKey());
						}
					}
				}
			}
		}
	}
	
	void GetGraffitis()
	{
		if(GetEngineVersion() == Engine_CSGO)
		{
			this.Schema.Rewind();
			
			// search after 'sticker_kits', graffitis are stored in same array as stickers..
			if(this.Schema.GotoFirstSubKey())
			{
				// found 'sticker_kits', lets read through it's KeyValue arrayed information..
				do
				{
					char section_name[32];
					this.Schema.GetSectionName(section_name, sizeof(section_name));
					
					if(StrEqual(section_name, "sticker_kits"))
					{
						if(this.Schema.GotoFirstSubKey())
						{
							do
							{
								char str_itemdef[11];
								this.Schema.GetSectionName(str_itemdef, sizeof(str_itemdef));
								
								if(strlen(str_itemdef) > 0)
								{
									int itemdef = StringToInt(str_itemdef);
									
									char sticker_material[64];
									this.Schema.GetString("sticker_material", sticker_material, sizeof(sticker_material));
									
									if(StrContains(sticker_material, "graffiti") != -1)
									{
										this.Graffitis.Push(itemdef);
										//PrintToServer("found graffiti %s '%s'", str_itemdef, sticker_material);
									}
								}
							}
							while(this.Schema.GotoNextKey());
							
							this.Schema.GoBack();
						}
					}
				}
				while(this.Schema.GotoNextKey());
				
				this.Schema.GoBack();
			}
		}
	}
}

ItemsGameRes ItemsGame;

void CallSchemaForward() {
	GlobalForward fwd = new GlobalForward("EconResData_OnItemsGameLoaded", ET_Ignore, Param_Any);
	KeyValues clone = view_as<KeyValues>(CloneHandle(ItemsGame.Schema));
	Call_StartForward(fwd);
	Call_PushCell(clone);
	Call_Finish();
	delete clone;
	delete fwd;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("EconResourceData");
	CreateNative("EconResData_LocalizeToken", Native_LocalizeToken);
	CreateNative("EconResData_GetColour", Native_GetColour);
	CreateNative("EconResData_GetItemName", Native_GetItemName);
	CreateNative("EconResData_GetItemClassname", Native_GetItemClassname);
	CreateNative("EconResData_ValidItemClassname", Native_ValidItemClassname);
	CreateNative("EconResData_GetKeyValues", Native_GetKeyValues);
	CreateNative("EconResData_GetGameSkins", Native_GetGameSkins);
	CreateNative("EconResData_GetGameClassnames", Native_GetGameClassnames);
	CreateNative("EconResData_ValidGameSkin", Native_ValidGameSkin);
	CreateNative("EconResData_GetGameGraffitis", Native_GetGameGraffitis);
	CreateNative("EconResData_ValidGameGraffiti", Native_ValidGameGraffiti);
	return APLRes_Success;
}

public void OnPluginStart()
{
	GetGameFolderName(folder_name, sizeof(folder_name));
	
	ItemsGame.Load();
	
	// Debug
	#if defined DEBUG
	RegConsoleCmd("sm_translate_token", TranslateTokenCmd, "Econ Resource Data - Translate a language token string.");
	#endif
}

#if defined DEBUG
Action TranslateTokenCmd(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[EconResData] Usage: sm_translate_token \"token here\"");
		return;
	}
	
	char token[64], translated[128];
	if(GetCmdArg(1, token, sizeof(token)) < 1)
	{
		ReplyToCommand(client, "[EconResData] Token key may not be NULL");
		return;
	}
	
	switch(ItemsGame.LocalizeToken(client, token, translated, sizeof(translated)))
	{
		case false: ReplyToCommand(client, "[EconResData] Token '%s' was not found :(", token);
		case true: ReplyToCommand(client, "[EconResData] Token '%s' was translated to '%s'", token, translated);
	}
}
#endif

// --

// EconResData_LocalizeToken(int client, const char[] token, char[] output, int maxlen)
any Native_LocalizeToken(Handle plugin, int params) {
	int client = GetNativeCell(1);
	
	int maxlen1 = GetNativeStringLengthEx(2);
	char[] token = new char[maxlen1];
	GetNativeString(2, token, maxlen1);
	
	int maxlen2 = GetNativeCell(4);
	char[] output = new char[maxlen2];
	bool rtrn = ItemsGame.LocalizeToken(client, token, output, maxlen2);
	
	SetNativeString(3, output, maxlen2);
	
	return rtrn;
}

// EconResData_GetColour(const char[] token)
any Native_GetColour(Handle plugin, int params) {
	int maxlen = GetNativeStringLengthEx(1);
	char[] token = new char[maxlen];
	GetNativeString(1, token, maxlen);
	
	int value;
	ItemsGame.Colours.GetValue(token, value);
	return value;
}

// EconResData_GetKeyValues()
any Native_GetKeyValues(Handle plugin, int params) {
	return CloneHandle(ItemsGame.Schema);
}

// EconResData_GetItemName(int client, int itemdef, char[] name, int maxlen)
any Native_GetItemName(Handle plugin, int params) {
	int client = GetNativeCell(1);
	int itemdef = GetNativeCell(2);
	int maxlen = GetNativeCell(4);
	char[] name = new char[maxlen];
	
	bool rtrn = ItemsGame.GetItemName(client, itemdef, name, maxlen);
	
	SetNativeString(3, name, maxlen);
	
	return rtrn;
}

// EconResData_GetItemClassname(int itemdef, char[] classname, int maxlen)
any Native_GetItemClassname(Handle plugin, int params) {
	int itemdef = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	char[] name = new char[maxlen];
	
	bool rtrn = ItemsGame.GetItemClassname(itemdef, name, maxlen);
	
	SetNativeString(2, name, maxlen);
	
	return rtrn;
}

any Native_ValidItemClassname(Handle plugin, int params) {
	int maxlen = GetNativeStringLengthEx(1);
	char[] classname = new char[maxlen];
	GetNativeString(1, classname, maxlen);
	
	switch(GetEngineVersion()) {
		case Engine_CSGO: {
			if(StrEqual(classname, "weapon_m4a1_silencer", false)
			|| StrEqual(classname, "weapon_usp_silencer", false)) return true;
		}
	}
	
	StrToLower(classname);
	
	return ItemsGame.Classnames.FindString(classname) != -1;
}

any Native_GetGameSkins(Handle plugin, int params) {
	if(ItemsGame.Skins == null) return view_as<Handle>(null);
	if(ItemsGame.Skins.Length < 1) return view_as<Handle>(null);
	return CloneHandle(ItemsGame.Skins);
}

any Native_GetGameClassnames(Handle plugin, int params) {
	if(ItemsGame.Classnames == null) return view_as<Handle>(null);
	if(ItemsGame.Classnames.Length < 1) return view_as<Handle>(null);
	return CloneHandle(ItemsGame.Classnames);
}

any Native_ValidGameSkin(Handle plugin, int params) {
	if(ItemsGame.Skins == null) return false;
	if(ItemsGame.Skins.Length < 1) return view_as<Handle>(null);
	return ItemsGame.Skins.FindValue(GetNativeCell(1)) != -1;
}

// EconResData_GetGameGraffitis()
any Native_GetGameGraffitis(Handle plugin, int params)
{
	return CloneHandle(ItemsGame.Graffitis);
}

// EconResData_ValidGameGraffiti(int itemdef)
any Native_ValidGameGraffiti(Handle plugin, int params)
{
	if(ItemsGame.Graffitis == null) return false;
	if(ItemsGame.Graffitis.Length < 1) return false;
	return ItemsGame.Graffitis.FindValue(GetNativeCell(1)) != -1;
}

// --

void StrToLower(char[] str) { for(int i = 0; i < strlen(str); i++) str[i] = CharToLower(str[i]); }

int GetNativeStringLengthEx(int param) {
	int value;
	GetNativeStringLength(param, value);
	return value+1;
}

bool StrContainsEx(const char[] str, const char[] subStr) {
	return view_as<bool>(StrContains(str, subStr, false) > -1);
}