local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local camera=workspace.CurrentCamera

local theme={
bg=Color3.fromRGB(8,10,18),
panel=Color3.fromRGB(18,22,40),
accent=Color3.fromRGB(252,238,9),
text=Color3.fromRGB(235,235,235),
sub=Color3.fromRGB(130,130,130)
}

local function lerp(a,b,t)return a+(b-a)*t end
local function clamp(v,a,b)return v<a and a or(v>b and b or v)end

local function inside(p,s,m)
return m.X>=p.X and m.X<=p.X+s.X and m.Y>=p.Y and m.Y<=p.Y+s.Y
end

local function getScale()
return math.clamp(camera.ViewportSize.X/1920,0.6,1)
end

local renderer={}
function renderer:create(t,p)
local o=Drawing.new(t)
for k,v in pairs(p or{})do o[k]=v end
return o
end

local input={
pos=Vector2.new(),
last=Vector2.new(),
delta=Vector2.new(),
down=false,
pressed=false,
released=false,
scroll=0,
keys={},
touch=nil
}

UIS.InputBegan:Connect(function(i,g)
if g then return end
if i.UserInputType==Enum.UserInputType.MouseButton1 then input.down=true input.pressed=true end
if i.UserInputType==Enum.UserInputType.Touch then input.down=true input.pressed=true input.touch=i input.pos=Vector2.new(i.Position.X,i.Position.Y)end
if i.KeyCode~=Enum.KeyCode.Unknown then input.keys[i.KeyCode]=true end
end)

UIS.InputChanged:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseMovement then input.pos=Vector2.new(i.Position.X,i.Position.Y)end
if i.UserInputType==Enum.UserInputType.Touch and i==input.touch then input.pos=Vector2.new(i.Position.X,i.Position.Y)end
if i.UserInputType==Enum.UserInputType.MouseWheel then input.scroll=i.Position.Z end
end)

UIS.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 then input.down=false input.released=true end
if i.UserInputType==Enum.UserInputType.Touch and i==input.touch then input.down=false input.released=true input.touch=nil end
if i.KeyCode~=Enum.KeyCode.Unknown then input.keys[i.KeyCode]=false end
end)

local lib={}

function lib:createWindow(opt)
local w={}
w.pos=Vector2.new(200,120)
w.size=Vector2.new(720,520)
w.tabs={}
w.active=nil
w.visible=true
w.scroll=0
w.velocity=0
w.dragging=false
w.dragStart=nil
w.dragThreshold=6
w.focus=nil
w.search=""
w.debounce=0

local bg=renderer:create("Square",{Filled=true})
local side=renderer:create("Square",{Filled=true})
local title=renderer:create("Text",{Size=20})

function w:createTab(name)
local t={name=name,sections={},hover=0}

function t:createSection()
local s={items={}}

function s:createButton(o)table.insert(s.items,{type="button",name=o.name,cb=o.callback or function()end})end
function s:createToggle(o)table.insert(s.items,{type="toggle",name=o.name,val=o.default or false,cb=o.callback or function()end})end
function s:createSlider(o)table.insert(s.items,{type="slider",name=o.name,val=o.default or o.min,min=o.min,max=o.max,cb=o.callback or function()end})end
function s:createDropdown(o)table.insert(s.items,{type="dropdown",name=o.name,val=o.default or o.options[1],opts=o.options,open=false,cb=o.callback or function()end})end
function s:createInput(o)table.insert(s.items,{type="input",name=o.name,val="",cb=o.callback or function()end})end
function s:createKeybind(o)table.insert(s.items,{type="keybind",name=o.name,key=o.default or Enum.KeyCode.E,mode=o.mode or"toggle",state=false,cb=o.callback or function()end})end

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

if not w.visible then bg.Visible=false side.Visible=false title.Visible=false return end

bg.Visible=true side.Visible=true title.Visible=true

bg.Position=w.pos
bg.Size=w.size*scale
bg.Color=theme.bg

local tabWidth=150*scale

side.Position=w.pos+Vector2.new(bg.Size.X-tabWidth,0)
side.Size=Vector2.new(tabWidth,bg.Size.Y)
side.Color=theme.panel

title.Position=w.pos+Vector2.new(15,10)
title.Text=opt.title or"UI"
title.Color=theme.accent

local headerSize=Vector2.new(bg.Size.X-tabWidth,40)

if input.pressed and inside(w.pos,headerSize,input.pos) then w.dragStart=input.pos end
if input.down and w.dragStart then if(input.pos-w.dragStart).Magnitude>w.dragThreshold then w.dragging=true end end
if w.dragging then w.pos=w.pos+input.delta end
if input.released then w.dragging=false w.dragStart=nil end

w.velocity=w.velocity+(-input.scroll*40)
w.velocity=w.velocity*0.9
w.scroll=math.max(w.scroll+w.velocity*dt,0)
input.scroll=0

local ty=w.pos.Y+70
for _,t in ipairs(w.tabs)do
local hover=inside(Vector2.new(w.pos.X+bg.Size.X-tabWidth,ty),Vector2.new(tabWidth,30*scale),input.pos)
t.hover=lerp(t.hover,hover and 1 or 0,dt*10)

if not t.txt then t.txt=renderer:create("Text",{Size=16})end
t.txt.Text=t.name
t.txt.Position=Vector2.new(w.pos.X+bg.Size.X-tabWidth+10,ty)
t.txt.Color=theme.text:Lerp(theme.accent,t.hover)

if hover and input.down then w.active=t end
ty=ty+35*scale
end

if w.active then
local y=w.pos.Y+70-w.scroll

for _,s in ipairs(w.active.sections)do
for _,it in ipairs(s.items)do

if w.search=="" or string.find(string.lower(it.name),string.lower(w.search)) then

local pos=Vector2.new(w.pos.X+20*scale,y)
local size=Vector2.new(240*scale,28*scale)
local hit=size+Vector2.new(input.touch and 6 or 0,input.touch and 6 or 0)

-- BUTTON
if it.type=="button"then
if not it.box then it.box=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})end
if inside(pos,hit,input.pos) and input.down and tick()>w.debounce then w.debounce=tick()+0.2 it.cb()end
it.box.Position=pos it.box.Size=size it.box.Color=theme.panel
it.txt.Text=it.name it.txt.Position=pos+Vector2.new(6,5) it.txt.Color=theme.text
y=y+34*scale
end

-- TOGGLE
if it.type=="toggle"then
if not it.box then it.box=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})end
if inside(pos,hit,input.pos) and input.down and tick()>w.debounce then w.debounce=tick()+0.2 it.val=not it.val it.cb(it.val)end
it.box.Position=pos it.box.Size=size it.box.Color=it.val and theme.accent or theme.panel
it.txt.Text=it.name it.txt.Position=pos+Vector2.new(6,5) it.txt.Color=theme.text
y=y+34*scale
end

-- SLIDER
if it.type=="slider"then
if not it.bar then it.bar=renderer:create("Square",{Filled=true})it.fill=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})end
if input.down and inside(pos,hit,input.pos) then local pct=clamp((input.pos.X-pos.X)/size.X,0,1)it.val=it.min+(it.max-it.min)*pct it.cb(it.val)end
local pct=(it.val-it.min)/(it.max-it.min)
it.bar.Position=pos+Vector2.new(0,20*scale) it.bar.Size=Vector2.new(size.X,6*scale) it.bar.Color=theme.panel
it.fill.Position=pos+Vector2.new(0,20*scale) it.fill.Size=Vector2.new(size.X*pct,6*scale) it.fill.Color=theme.accent
it.txt.Text=it.name.." "..math.floor(it.val) it.txt.Position=pos it.txt.Color=theme.text
y=y+38*scale
end

-- DROPDOWN
if it.type=="dropdown"then
if not it.box then it.box=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})it.draw={}end
if inside(pos,hit,input.pos) and input.down and tick()>w.debounce then w.debounce=tick()+0.2 it.open=not it.open end
it.box.Position=pos it.box.Size=size it.box.Color=theme.panel
it.txt.Text=it.name..": "..it.val it.txt.Position=pos+Vector2.new(6,5) it.txt.Color=theme.text
local oy=pos.Y+size.Y
if it.open then
for _,opt in ipairs(it.opts)do
if not it.draw[opt] then it.draw[opt]=renderer:create("Text",{Size=15})end
local optPos=Vector2.new(pos.X,oy)
if inside(optPos,Vector2.new(size.X,22*scale),input.pos) and input.down then it.val=opt it.cb(opt) it.open=false end
it.draw[opt].Text=opt it.draw[opt].Position=optPos+Vector2.new(6,0) it.draw[opt].Color=theme.sub
oy=oy+22*scale
end
end
y=y+size.Y+(it.open and #it.opts*22*scale or 0)
end

-- INPUT
if it.type=="input"then
if not it.box then it.box=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})end
if inside(pos,hit,input.pos) and input.down then w.focus=it end
if w.focus==it then
for k,v in pairs(input.keys)do
if v then
if k==Enum.KeyCode.Backspace then it.val=it.val:sub(1,-2)
elseif #k.Name==1 then it.val=it.val..k.Name end
it.cb(it.val)
end
end
end
it.box.Position=pos it.box.Size=size it.box.Color=theme.panel
it.txt.Text=it.name..": "..it.val it.txt.Position=pos+Vector2.new(6,5) it.txt.Color=theme.text
y=y+34*scale
end

-- KEYBIND
if it.type=="keybind"then
if not it.box then it.box=renderer:create("Square",{Filled=true})it.txt=renderer:create("Text",{Size=16})end
if inside(pos,hit,input.pos) and input.down then w.focus=it end
if w.focus==it then
for k,v in pairs(input.keys)do if v then it.key=k w.focus=nil end end
end
if input.keys[it.key] then
if it.mode=="toggle" then it.state=not it.state it.cb(it.state)
elseif it.mode=="hold" then it.cb(true)end
end
it.box.Position=pos it.box.Size=size it.box.Color=theme.panel
it.txt.Text=it.name.." ["..it.key.Name.."]" it.txt.Position=pos+Vector2.new(6,5) it.txt.Color=theme.text
y=y+34*scale
end

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
