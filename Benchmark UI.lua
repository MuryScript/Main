local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Http = game:GetService("HttpService")
local camera = workspace.CurrentCamera

local theme = {
    bg = Color3.fromRGB(8,10,18),
    panel = Color3.fromRGB(18,22,40),
    accent = Color3.fromRGB(252,238,9),
    text = Color3.fromRGB(235,235,235),
    sub = Color3.fromRGB(130,130,130)
}

local function lerp(a,b,t) return a+(b-a)*t end
local function clamp(v,a,b) return v<a and a or (v>b and b or v) end

local function inside(p,s,m)
    return m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+s.Y
end

local function getScale()
    return math.clamp(camera.ViewportSize.X / 1920, 0.6, 1)
end

local renderer = {}
function renderer:create(t,p)
    local o = Drawing.new(t)
    for k,v in pairs(p or {}) do o[k]=v end
    return o
end

local input = {
    pos = Vector2.new(),
    last = Vector2.new(),
    delta = Vector2.new(),
    down = false,
    pressed = false,
    released = false,
    scroll = 0,
    keys = {},
    touch = nil
}

UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        input.down=true input.pressed=true
    end
    if i.UserInputType==Enum.UserInputType.Touch then
        input.down=true input.pressed=true input.touch=i
        input.pos=Vector2.new(i.Position.X,i.Position.Y)
    end
    if i.KeyCode~=Enum.KeyCode.Unknown then
        input.keys[i.KeyCode]=true
    end
end)

UIS.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement then
        input.pos=Vector2.new(i.Position.X,i.Position.Y)
    end
    if i.UserInputType==Enum.UserInputType.Touch and i==input.touch then
        input.pos=Vector2.new(i.Position.X,i.Position.Y)
    end
    if i.UserInputType==Enum.UserInputType.MouseWheel then
        input.scroll=i.Position.Z
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        input.down=false input.released=true
    end
    if i.UserInputType==Enum.UserInputType.Touch and i==input.touch then
        input.down=false input.released=true input.touch=nil
    end
    if i.KeyCode~=Enum.KeyCode.Unknown then
        input.keys[i.KeyCode]=false
    end
end)

local lib = {}

function lib:createWindow(opt)
    local w = {}

    w.pos = Vector2.new(200,120)
    w.size = Vector2.new(720,520)
    w.tabs = {}
    w.active = nil
    w.visible = true

    w.scroll = 0
    w.targetScroll = 0
    w.velocity = 0

    w.dragging=false
    w.dragStart=nil
    w.dragThreshold=6

    w.focus=nil
    w.search=""

    local config = {}
    local file="ui_cfg.json"
    if isfile(file) then config=Http:JSONDecode(readfile(file)) end
    local function save() writefile(file,Http:JSONEncode(config)) end

    local bg = renderer:create("Square",{Filled=true})
    local side = renderer:create("Square",{Filled=true})
    local title = renderer:create("Text",{Size=20})

    function w:notify(t)
        print("[UI]",t)
    end

    function w:createTab(name)
        local t={name=name,sections={},hover=0}

        function t:createSection()
            local s={items={}}

            function s:createToggle(o)
                local v=config[o.name] or o.default or false
                config[o.name]=v
                table.insert(s.items,{type="toggle",name=o.name,val=v,cb=o.callback})
            end

            function s:createButton(o)
                table.insert(s.items,{type="button",name=o.name,cb=o.callback})
            end

            function s:createSlider(o)
                local v=config[o.name] or o.default or o.min
                config[o.name]=v
                table.insert(s.items,{type="slider",name=o.name,val=v,min=o.min,max=o.max,cb=o.callback})
            end

            function s:createDropdown(o)
                local v=config[o.name] or o.default or o.options[1]
                config[o.name]=v
                table.insert(s.items,{type="dropdown",name=o.name,val=v,opts=o.options,open=false,cb=o.callback})
            end

            function s:createInput(o)
                local v=config[o.name] or ""
                config[o.name]=v
                table.insert(s.items,{type="input",name=o.name,val=v,cb=o.callback})
            end

            table.insert(t.sections,s)
            return s
        end

        table.insert(w.tabs,t)
        if not w.active then w.active=t end
        return t
    end

    RS.RenderStepped:Connect(function(dt)
        input.delta=input.pos-input.last
        input.last=input.pos

        local scale=getScale()

        if not w.visible then
            bg.Visible=false side.Visible=false title.Visible=false
            return
        end

        bg.Visible=true side.Visible=true title.Visible=true

        bg.Position=w.pos
        bg.Size=w.size*scale
        bg.Color=theme.bg

        side.Position=w.pos+Vector2.new(bg.Size.X-150*scale,0)
        side.Size=Vector2.new(150*scale,bg.Size.Y)
        side.Color=theme.panel

        title.Position=w.pos+Vector2.new(15,10)
        title.Text=opt.title or "UI"
        title.Color=theme.accent

        local headerSize=Vector2.new(bg.Size.X-150*scale,40)

        if input.pressed and inside(w.pos,headerSize,input.pos) then
            w.dragStart=input.pos
        end

        if input.down and w.dragStart then
            if (input.pos-w.dragStart).Magnitude>w.dragThreshold then
                w.dragging=true
            end
        end

        if w.dragging then
            w.pos=w.pos+input.delta
        end

        if input.released then
            w.dragging=false
            w.dragStart=nil
        end

        w.velocity = w.velocity + (-input.scroll*40)
        w.velocity = w.velocity * 0.9
        w.scroll = w.scroll + w.velocity*dt
        w.scroll = math.max(w.scroll,0)
        input.scroll=0

        local ty=w.pos.Y+70
        for _,t in ipairs(w.tabs) do
            local hover=inside(Vector2.new(w.pos.X+bg.Size.X-150,ty),Vector2.new(150,30),input.pos)
            t.hover=lerp(t.hover,hover and 1 or 0,dt*10)

            if not t.txt then t.txt=renderer:create("Text",{Size=16}) end
            t.txt.Text=t.name
            t.txt.Position=Vector2.new(w.pos.X+bg.Size.X-140,ty)
            t.txt.Color=theme.text:Lerp(theme.accent,t.hover)

            if hover and input.down then w.active=t end

            ty=ty+35
        end

        if w.active then
            local y=w.pos.Y+70-w.scroll

            for _,s in ipairs(w.active.sections) do
                for _,it in ipairs(s.items) do

                    if w.search~="" and not string.find(string.lower(it.name),string.lower(w.search)) then
                        continue
                    end

                    local pos=Vector2.new(w.pos.X+20,y)

                    if it.type=="button" then
                        if not it.box then
                            it.box=renderer:create("Square",{Filled=true})
                            it.txt=renderer:create("Text",{Size=16})
                        end

                        if inside(pos,Vector2.new(220,26),input.pos) and input.down then
                            it.cb()
                        end

                        it.box.Position=pos
                        it.box.Size=Vector2.new(220,26)
                        it.box.Color=theme.panel

                        it.txt.Text=it.name
                        it.txt.Position=pos+Vector2.new(6,5)
                        it.txt.Color=theme.text

                        y=y+32
                    end

                end
            end
        end

        input.pressed=false
        input.released=false
    end)

    return w
end

return lib
