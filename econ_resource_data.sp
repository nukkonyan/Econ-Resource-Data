#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0

/*
 * Credits to legendary Dr. McKay for the language file parsing code, loaning from enhanced_items.sp (Enhanced Item Notifications) plugin
 * Credits to dragokas for some fixes.
 * Check 'Enhanced Item Notifications' made by legendary Dr. McKay.
*/

public Plugin myinfo = {
	name = "Econ Resource Data",
	author = "Tk /id/Teamkiller324",
	description = "Localize tokens and translation strings.",
	version = "1.0.1",
	url = "https://steamcommunity.com/id/Teamkiller324"
}

#define items_game_txt "scripts/items/items_game.txt"
#define clientscheme_res "resource/clientscheme.res"
char folder_name[16];

enum struct ItemsGameRes {
	KeyValues Schema;
	StringMap Languages;
	StringMap Colours;
	
	void Load() {
		this.Schema = new KeyValues("items_game");
		this.Schema.ImportFromFile(items_game_txt);
		
		this.Languages = new StringMap();
		this.Colours = new StringMap();
		
		KeyValues kv = new KeyValues("Scheme");
		kv.ImportFromFile(clientscheme_res);
		
		if(kv.JumpToKey("Colors")) {
			kv.GotoFirstSubKey(false);
			
			do {
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
		
		if(kv.JumpToKey("BaseSettings")) {
			kv.GotoFirstSubKey(false);
			
			do {
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
	}
	
	bool LocalizeToken(int client, const char[] token, char[] output, int maxlen) {
		StringMap lang = this.GetLanguage(client);
		if(lang == null) {
			LogError("Unable to localize token '%s' for server language!", token);
			return false;
		}
		
		return lang.GetString(token, output, maxlen);
	}
	
	StringMap GetLanguage(int client) {
		int language = (client == LANG_SERVER) ? GetServerLanguage() : GetClientLanguage(client);
		
		char language_name[64];
		GetLanguageInfo(language, _, _, language_name, sizeof(language_name));
		
		StringMap lang;
		if(!this.Languages.GetValue(language_name, lang)) {
			lang = this.ParseLanguage(language_name);
			this.Languages.SetValue(language_name, lang);
		}
		
		if(lang == null && client != LANG_SERVER) return this.GetLanguage(LANG_SERVER);
		//else if(lang == null) return null;
		
		return lang;
	}
	
	StringMap ParseLanguage(const char[] language_name) {
		char filename[64];
		Format(filename, sizeof(filename), "resource/%s_%s.txt", folder_name, language_name);
		
		File file = OpenFile(filename, "r");
		
		if(file == null) return null;
		
		StringMap lang = new StringMap();
		lang.SetString("__name__", language_name);
		
		int data, i = 0, high_surrogate, low_surrogate;
		char line[3072];
		while(ReadFileCell(file, data, 2) == 1) {
			if(high_surrogate) {
				// for characters in range 0x10000 <= X <= 0x10FFFF
				low_surrogate = data;
				data = ((high_surrogate - 0xD800) << 10) + (low_surrogate - 0xDC00) + 0x10000;
				line[i++] = ((data >> 18) & 0x07) | 0xF0;
				line[i++] = ((data >> 12) & 0x3F) | 0x80;
				line[i++] = ((data >> 6) & 0x3F) | 0x80;
				line[i++] = (data & 0x3F) | 0x80;
				high_surrogate = 0;
			} else if(data < 0x80) {
				// It's a single-byte character
				line[i++] = data;
				
				if(data == '\n') {
					line[i] = '\0';
					this.HandleLangLine(line, lang);
					i = 0;
				}
			} else if(data < 0x800) {
				// It's a two-byte character
				line[i++] = ((data >> 6) & 0x1F) | 0xC0;
				line[i++] = (data & 0x3F) | 0x80;
			} else if(data <= 0xFFFF) {
				if(0xD800 <= data <= 0xDFFF) {
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
	
	void HandleLangLine(char[] line, StringMap lang) {
		TrimString(line);
		
		// Not a line containing at least one quoted string
		if(line[0] != '"') return;
		
		char token[128], value[1024];
		int pos = BreakString(line, token, sizeof(token));
		
		// This line doesn't have two quoted strings
		if(pos == -1) return;
		
		BreakString(line[pos], value, sizeof(value));
		lang.SetString(token, value);
	}
}

ItemsGameRes ItemsGame;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("EconResourceData");
	CreateNative("EconResData_LocalizeToken", Native_LocalizeToken);
	CreateNative("EconResData_GetColour", Native_GetColour);
	CreateNative("EconResData_GetKeyValues", Native_GetKeyValues);
}

public void OnPluginStart() {
	switch(GetEngineVersion()) {
		case Engine_TF2: folder_name = "tf";
		default: GetGameFolderName(folder_name, sizeof(folder_name));
	}
	
	ItemsGame.Load();
}

// --

// EconResData(int client, const char[] token, char[] output, int maxlen)
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
	return ItemsGame.Schema;
}

// --

void StrToLower(char[] str) { for(int i = 0; i < strlen(str); i++) str[i] = CharToLower(str[i]); }

int GetNativeStringLengthEx(int param) {
	int value;
	GetNativeStringLength(param, value);
	return value++;
}