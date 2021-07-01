//This file contains a class called NuHub, which has the purpose of carrying around a bunch of of data to make getting and setting it around easier.

#include "NuMenuCommon.as";
#include "NuTextCommon.as";
#include "NumanLib.as";


funcdef bool RENDER_CALLBACK();

class RenderDetails
{
    RenderDetails(RENDER_CALLBACK@ _func)
    {
        @func = @_func;   

        @image = @null;
    }

    RenderDetails(Nu::NuImage@ _image, Vec2f _pos, u16 _frame = 0, bool _world_pos = false, Vec2f _old_pos = Vec2f(-1.0f, -1.0f))
    {
        func = @null;

        @image = @_image;
        pos = _pos;
        
        if(_old_pos == Vec2f(-1.0f, -1.0f))//Old pos not set?
        {
            old_pos = _pos;//Set it to _pos
        }
        else//Old pos is set
        {
            old_pos = _old_pos;//Set it
        }

        frame = _frame;
        world_pos = _world_pos;
    }
    private RENDER_CALLBACK@ func;
    RENDER_CALLBACK@ getFunc()
    {
        return @func;
    }

    Nu::NuImage@ image;
    Vec2f old_pos;
    Vec2f pos;
    u16 frame;
    bool world_pos;
}

bool getHub(NuHub@ &out _hub)
{
    if(!getRules().get("NuHub", @_hub)) { Nu::Error("Failed to get NuHub. Make sure NuToolsLogic is before anything else that tries to use it."); return false; }
    return true;
}

class NuHub
{
    NuHub()
    {
        SetupArrays();
        
        SetupGlobalVars();
    }
    
    void SetupArrays()
    {
        menus = array<NuMenu::IMenu@>();
        buttons = array<NuMenu::MenuButton@>();
        
        fonts = array<NuFont@>();

        wire_positions = array<array<u16>>(team_wire_amount);//Init the array that stores where all the wires are in the map with their connected network

        render_details = array<array<NuMenu::RenderDetails@>>(Render::layer_count);

        for(u16 i = 0; i < render_details.size(); i++)
        {
            render_details[i] = array<NuMenu::RenderDetails@>();
        }
    }


    //
    //Rendering
    //
    int posthudid;
    int prehudid;
    int postworldid;
    int objectsid;
    int tilesid;
    int backgroundid;
    void SetupRendering()
    {
        posthudid = Render::addScript(Render::layer_posthud, "NuToolsRendering.as", "MenusPostHud", 0.0f);
        prehudid = Render::addScript(Render::layer_prehud, "NuToolsRendering.as", "MenusPreHud", 0.0f);
        postworldid = Render::addScript(Render::layer_postworld, "NuToolsRendering.as", "MenusPostWorld", 0.0f);
        objectsid = Render::addScript(Render::layer_objects, "NuToolsRendering.as", "MenusObjects", 0.0f);
        tilesid = Render::addScript(Render::layer_tiles, "NuToolsRendering.as", "MenusTiles", 0.0f);
        backgroundid = Render::addScript(Render::layer_background, "NuToolsRendering.as", "MenusBackground", 0.0f);
    }


    f32 FRAME_TIME; // last frame time
    float MARGIN;//How many pixels away will things stop drawing from outside the screen.
    void SetupGlobalVars()
    {
        FRAME_TIME = 0.0f;
        MARGIN = 255.0f;
    }


    array<array<NuMenu::RenderDetails@>> render_details;

    void RenderImage(Render::ScriptLayer layer, RENDER_CALLBACK@ _func)
    {
        if(layer > render_details.size()) { Nu::Error("Layer beyond max layer"); return; }

        render_details[layer].push_back(@RenderDetails(_func));//Optimize this. Improve this. Think how the dictionary was optimized. Numan TODO
    }
    void RenderImage(Render::ScriptLayer layer, Nu::NuImage@ _image, Vec2f _pos, u16 _frame = 0, bool is_world_pos = false)
    {
        if(layer > render_details.size()) { Nu::Error("Layer beyond max layer"); return; }

        render_details[layer].push_back(@RenderDetails(_image, _pos, _frame, is_world_pos));//Optimize this. Improve this. Think how the dictionary was optimized. Numan TODO
    }
    void RenderClear()
    {
        for(u16 i = 0; i < render_details.size(); i++)
        {
            render_details[i].resize(0);//Wipe array. (TODO, OPTIMIZE THIS)
        }
    }

    //
    //Rendering
    //


    //
    //Signals/Wires
    //

    u8 team_wire_amount = 3;
    array<array<u16>> wire_positions;

    //
    //Signals/Wires
    //

    //
    //Fonts
    //
    
    private array<NuFont@> fonts;
    array<NuFont@> getFonts()
    {
        return fonts;
    }
    
    void addFont(NuFont@ _font)
    {
        if(_font == @null){ error("addFont(NuFont@): attempted to add null font."); return;}
        
        if(getFont(_font.basefont.name) != @null) { warning("addFont(NuFont@): Font attempted to add already existed."); return; }
        
        fonts.push_back(@_font);
    }
    void addFont(string font_name, string font_file, bool has_alpha = true)
    {
        if(getFont(font_name) != @null) { warning("addFont(string): Font attempted to add already existed."); return; }

        NuFont@ font = NuFont(font_name, font_file, has_alpha);

        if(font == @null)
        {
            Nu::Error("Font was still null after creation. Somehow.");
        }

        fonts.push_back(@font);
    }
    
    NuFont@ getFont(string font_name)
    {
        for(u16 i = 0; i < fonts.size(); i++)
        {
            if(fonts[i].basefont.name == font_name)
            {
                return @fonts[i];
            }
        }
        return @null;
    }

    bool FontExists(string font_name)
    {
        if(getFont(font_name) != @null)
        {
            return true;
        }

        return false;
    }

    
    //getFont()//

    //
    //Fonts
    //




    //
    //Menus
    //

    bool addMenuToList(NuMenu::IMenu@ _menu)
    {
        if(_menu == @null) { Nu::Error("Menu to be added was null"); return false; }
        menus.push_back(_menu);
        buttons.push_back(@null);
        
        //NuMenu::MenuButton@ button = cast<NuMenu::MenuButton@>(_menu);
        //if(button != @null) { print("WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWaWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW"); }
        //buttons.push_back(button);

        return true;
    }

    bool addMenuToList(NuMenu::MenuButton@ _menu)
    {
        if(_menu == @null) { Nu::Error("Menu to be added was null"); return false; }

        menus.push_back(_menu);
        buttons.push_back(_menu);

        return true;
    }

    bool removeMenuFromList(u16 i)
    {
        if(i >= menus.size())
        {
            error("Tried to remove menu equal to or above the menu size."); return false;
        }

        menus.removeAt(i);
        buttons.removeAt(i);

        return true;
    }
    
    bool removeMenuFromList(string _name)
    {
        int _namehash = _name.getHash();
        for(u16 i = 0; i < menus.size(); i++)
        {
            if(menus[i].getNameHash() == _namehash)
            {
                menus.removeAt(i);
                buttons.removeAt(i);
                i--;
            }
        }

        return true;
    }


    //Returns an array of all the positions of menus with _name in the menu array. 
    array<u16> getMenuPositions(string _name)
    {   
        array<u16> _menu_positions();
        
        int _namehash = _name.getHash();
        for(u16 i = 0; i < menus.size(); i++)
        {
            if(menus[i].getNameHash() == _namehash)
            {
                _menu_positions.push_back(i);
            }
        }

        return _menu_positions;
    }

    u16 getMenuListSize()
    {
        return menus.size();
    }

    //False being returned means the code tried to get past the max menu size.
    bool getMenuFromList(u16 i, NuMenu::IMenu@ &out imenu)
    {
        if(i >= menus.size()) { error("Tried to get menu equal to or above the menu size."); @imenu = @null; return false; }

        @imenu = @menus[i];

        return true;
    }

    //Get the first IMenu from the menus array with _name.
    //False being returned means no menus were found.
    bool getMenuFromList(string _name, NuMenu::IMenu@ &out imenu)
    {
        array<u16> _menus();
        _menus = getMenuPositions(_name);
        if(_menus.size() > 0)
        {
            @imenu = @menus[_menus[0]];
            return true;
        }
        else
        {
            return false;
        }
    }

    void ClearMenuList()
    {
        menus.clear();
        buttons.clear();
    }

    //Return IMenu at the position.
    //NuMenu::IMenu@ get_opIndex(int idx) const
    //{
    //    if(idx >= menus.size()) { error("Tried to get menu out of bounds."); return @null; }
    //    return @menus[idx];
    //}
    

    array<NuMenu::IMenu@> menus;

    array<NuMenu::MenuButton@> buttons;//Since casting is very broken, this is a way to sidestep the issue.

    //
    //Menus
    //


}
//Don't let more of one of this exist at once.