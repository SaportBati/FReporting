local imgui = require 'imgui'
local imadd = require 'imgui_addons'
local keys = require 'vkeys'
local encoding = require 'encoding'
local lfs = require 'lfs'
local json = require 'dkjson'
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'

encoding.default = 'CP1251'
u8 = encoding.UTF8

-- Auto-update variables
local update_state = false
local script_vers = 12
local script_vers_text = "3.09"
local script_path = thisScript().path
local script_url = "https://github.com/SaportBati/FReporting/raw/refs/heads/main/FReporting.luac"
local update_path = getWorkingDirectory() .. "/update.ini"
local update_url = "https://raw.githubusercontent.com/SaportBati/FReporting/refs/heads/main/update%2Cini"

local main_window_state = imgui.ImBool(false)
local ActiveFluid = imgui.ImBool(false)
local tiplovli = false
local test_text_buffer = imgui.ImBuffer(256)

local logo = {
    file = getWorkingDirectory() .. '\\FReporting\\FReportingLOGO.png',
    handle = nil
}

local fontsize17 = nil
local fontsize19 = nil
local fontsize22 = nil

-- ���������� ��� �������� � ��������
local sliderValue = imgui.ImInt(30)
local speed = 30
local spamEnabled = false
local qPressed = false
local anyWindowOpen = false
local spamType = imgui.ImInt(1) -- 1 - toggle, 2 - hold
local holdActive = false -- ���� ��� ������ hold

-- ���������� ��� �����
local audio = nil
local audio2 = nil
local audio3 = nil
local audio4 = nil
local audio5 = nil
local soundEnabled = imgui.ImBool(false) -- ������������� ��� ImBool
local sound_file_name = "click.mp3"
local sound_file_name2 = "click1.mp3"
local sound_file_name3 = "click2.mp3"
local sound_file_name4 = "click3.mp3"
local sound_file_name5 = "click4.mp3"
local sound_folder_path = getWorkingDirectory() .. '\\FReporting\\saund'
local sound_file_path = sound_folder_path .. '\\' .. sound_file_name
local sound_file_path2 = sound_folder_path .. '\\' .. sound_file_name2
local sound_file_path3 = sound_folder_path .. '\\' .. sound_file_name3
local sound_file_path4 = sound_folder_path .. '\\' .. sound_file_name4
local sound_file_path5 = sound_folder_path .. '\\' .. sound_file_name5
local windowOpened = false
local fAlpha = 0.00
local windowYOffset = 0.0  -- �������� ���� �� Y
local soundVolume = imgui.ImInt(50) -- ��������� �����
local soundType = imgui.ImInt(1)  -- ��� ����� 1 ��� 2

-- ������� ��� �������� � �������� �����
local function checkAndCreateFolder(folderPath)
    if not lfs.attributes(folderPath) then
        local success, err = lfs.mkdir(folderPath)
        if not success then
            print("�� ������� ������� �����: " .. err)
        else
            print("����� ������� �������: " .. folderPath)
        end
    end
end

-- ������� ��� �������� �������� �� �����
local function loadSettings()
    local file = io.open(getWorkingDirectory() .. '\\FReporting\\settings.json', 'r')
    if file then
        local content = file:read("*a")
        local settings = json.decode(content)

        if settings then
            sliderValue.v = settings.sliderValue or 30
            speed = sliderValue.v
            ActiveFluid.v = settings.ActiveFluid or false
            tiplovli = settings.tiplovli or false
            soundEnabled.v = settings.soundEnabled or false
            soundVolume.v = settings.soundVolume or 50
            soundType.v = settings.soundType or 1
            spamType.v = settings.spamType or 1
        end
        file:close()
    end
end

-- ������� ��� ���������� �������� � ����
local function saveSettings()
    local settings = {
        sliderValue = sliderValue.v,
        ActiveFluid = ActiveFluid.v,
        tiplovli = tiplovli,
        soundEnabled = soundEnabled.v,
        soundVolume = soundVolume.v,
        soundType = soundType.v,
        spamType = spamType.v,
    }

    local file = io.open(getWorkingDirectory() .. '\\FReporting\\settings.json', 'w')
    if file then
        local content = json.encode(settings, { indent = true })
        file:write(content)
        file:close()
    else
        sampAddChatMessage("[FReporting] {FF0000}�� ������� ��������� ���������.", 0xFF0000)
    end
end

-- ������� ��� �������� ����������
local function checkForUpdates()
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            local updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("[FReporting] {FFFFFF}���� ����������! ������: {00c2c2}" .. updateIni.info.vers_text, 0x00c2c2)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
end

-- ������� ��� ��������������� �����
local function playSound()
    if soundType.v == 1 then
        if audio then
            setAudioStreamState(audio, 1)
            setAudioStreamVolume(audio, soundVolume.v)
        end
    elseif soundType.v == 2 then
        if audio2 then
            setAudioStreamState(audio2, 1)
            setAudioStreamVolume(audio2, soundVolume.v)
        end
     elseif soundType.v == 3 then
        if audio3 then
            setAudioStreamState(audio3, 1)
            setAudioStreamVolume(audio3, soundVolume.v)
        end
    elseif soundType.v == 4 then
      if audio4 then
          setAudioStreamState(audio4, 1)
          setAudioStreamVolume(audio4, soundVolume.v)
        end
      elseif soundType.v == 5 then
      if audio5 then
            setAudioStreamState(audio5, 1)
            setAudioStreamVolume(audio5, soundVolume.v)
        end
    end
end

-- ������� ��� ��������� �����
local function stopSound()
    if audio then
        setAudioStreamState(audio, 0)
    end
    if audio2 then
        setAudioStreamState(audio2, 0)
    end
    if audio3 then
         setAudioStreamState(audio3, 0)
    end
    if audio4 then
        setAudioStreamState(audio4, 0)
     end
     if audio5 then
         setAudioStreamState(audio5, 0)
    end
end

-- ������� ��� ������� /plays
function cmd_plays()
    soundEnabled.v = not soundEnabled.v
    if soundEnabled.v then
        sampAddChatMessage(string.format("[%s]: ���� �����������", thisScript().name), 0x40FF40)
        playSound()
    else
        sampAddChatMessage(string.format("[%s]: ���� �������������", thisScript().name), 0xFF4040)
        stopSound()
    end
end

-- ������� ��� �������� �������� ����
local function UpdateAlpha(menustate)
    if (menustate) then
        if (fAlpha ~= 1.00) then fAlpha = fAlpha + 0.1 end -- ����������� ��� ������������
        if (windowYOffset > 0) then windowYOffset = windowYOffset - 50 end  -- ����������� ��� ��������
    else
        if (fAlpha ~= 0.00) then fAlpha = fAlpha - 0.1 end -- ����������� ��� ������������
         if (windowYOffset < 250) then windowYOffset = windowYOffset + 50 end  -- ����������� ��� ��������
    end
    if (fAlpha > 1.00) then fAlpha = 1.00 end
    if (fAlpha < 0.00) then fAlpha = 0.00 end
     if (windowYOffset > 250) then windowYOffset = 250 end
     if (windowYOffset < 0) then windowYOffset = 0 end
    apply_custom_style()
end

-- ������� ��� ������
function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    style.Alpha = fAlpha
      
    -- ���������� SliderInt
    style.Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.4, 0.4, 0.4, 1.0) -- �����
    style.Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.6, 0.6, 0.6, 1.0) -- ������-�����
    style.Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.278, 0.278, 0.278, 1)
    style.Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.3, 0.3, 0.3, 1)
    style.Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.2, 0.2, 0.2, 1)

        -- ���������� ������
    style.Colors[imgui.Col.Button] = imgui.ImVec4(0.278, 0.278, 0.278, 1)
    style.Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.3, 0.3, 0.3, 1)
    style.Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.2, 0.2, 0.2, 1)
    style.FrameRounding = 3
end

-- ��������� ToggleButton
local function CustomToggleButton(label, v, size, alpha, soundOnToggle)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local offsetY = 3  -- �������� ������������� ����
     pos.y = pos.y + offsetY;
    local rectSize = size or imgui.ImVec2(30, 20)
    local rectEnd = imgui.ImVec2(pos.x + rectSize.x, pos.y + rectSize.y)
    local circleRadius = rectSize.y / 2 - 2
    local circleCenter = imgui.ImVec2(pos.x + (v.v and rectSize.x - circleRadius - 2 or circleRadius + 2), pos.y + rectSize.y / 2)
    
    local colorBg = v.v and imgui.ImVec4(0.4, 0.4, 0.4, alpha) or imgui.ImVec4(0.2, 0.2, 0.2, alpha) -- ����� ��� ���, �����-����� ��� ����
    drawList:AddRectFilled(pos, rectEnd, imgui.ColorConvertFloat4ToU32(colorBg), 4)
    drawList:AddCircleFilled(circleCenter, circleRadius, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, alpha)))


    imgui.InvisibleButton(label, rectSize)
    if imgui.IsItemClicked() then
        v.v = not v.v
        if soundOnToggle then
          if soundEnabled.v then
            playSound()
           end
        end
          return true
    end
     return false
end

-- ��������� SliderInt
local function CustomSliderInt(label, v, min, max, alpha)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local offsetY = 5;  -- �������� �������� ����
    pos.y = pos.y + offsetY
    local barSize = imgui.ImVec2(200, 10) -- �������� ����� ������
    local barEnd = imgui.ImVec2(pos.x + barSize.x, pos.y + barSize.y)
    local circleRadius = 10
    local normalizedValue = (v.v - min) / (max - min)
    local circleX = pos.x + normalizedValue * barSize.x
    local circleCenter = imgui.ImVec2(circleX, pos.y + barSize.y / 2)

    -- ������ ������
    drawList:AddRectFilled(pos, barEnd, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.6, 0.6, 0.6, alpha)), 5)
	-- ������ ����������� �����
    local fillEnd = imgui.ImVec2(pos.x + normalizedValue * barSize.x, pos.y + barSize.y)
    drawList:AddRectFilled(pos, fillEnd, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.4, 0.4, 0.4, alpha)), 5) -- ����� ����

    -- ������ ������� �������������
    drawList:AddCircleFilled(circleCenter, circleRadius, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, alpha)))
    drawList:AddCircle(circleCenter, circleRadius, imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.4, 0.4, 0.4, alpha)), 20, 2) -- ������� �����

    -- ������ ��������� ������ ��� ��������� �����
    imgui.SetCursorScreenPos(imgui.ImVec2(pos.x-circleRadius*2,pos.y-circleRadius*2))
    imgui.InvisibleButton(label, imgui.ImVec2(barSize.x + circleRadius*4, circleRadius*4) )
     
      if imgui.IsItemActive() and imgui.IsMouseDragging() then
        local mouseX = imgui.GetIO().MousePos.x
        local newNormalizedValue = (mouseX - pos.x) / barSize.x
        newNormalizedValue = math.max(0, math.min(1, newNormalizedValue))
        v.v = math.floor(min + newNormalizedValue * (max - min))
         return true
    end
      -- ���������� ������� �������� � ���� ���������
     if imgui.IsItemHovered() then
         imgui.SetTooltip(u8"" .. v.v)
    end
    return false
end

local function CustomRadioButton(label, v, id, size, alpha)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()
    local offsetY = 3  -- �������� ������������� ����
    pos.y = pos.y + offsetY;
    local rectSize = size or imgui.ImVec2(20, 20)
    local rectEnd = imgui.ImVec2(pos.x + rectSize.x, pos.y + rectSize.y)
    local rectRounding = 4
    local colorBg = (v.v == id) and imgui.ImVec4(0.4, 0.4, 0.4, alpha) or imgui.ImVec4(0.2, 0.2, 0.2, alpha) -- ����� ��� ���, �����-����� ��� ����
    local innerRectSize = imgui.ImVec2(rectSize.x * 0.5, rectSize.y * 0.5)
    local innerRectPos = imgui.ImVec2(pos.x + rectSize.x * 0.25, pos.y + rectSize.y * 0.25)
    drawList:AddRectFilled(pos, rectEnd, imgui.ColorConvertFloat4ToU32(colorBg), rectRounding)

    if v.v == id then
      drawList:AddRectFilled(innerRectPos, imgui.ImVec2(innerRectPos.x+innerRectSize.x, innerRectPos.y+innerRectSize.y), imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1, 1, 1, alpha)), rectRounding/2)
    end


    imgui.InvisibleButton(label, rectSize)
    if imgui.IsItemClicked() then
        v.v = id
          return true
    end
     return false
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("update", cmd_update)
    sampRegisterChatCommand("plays", cmd_plays)

    checkForUpdates()

    id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)

    local fReportingPath = getWorkingDirectory() .. '\\FReporting'
    checkAndCreateFolder(fReportingPath)
    local sound = getWorkingDirectory() .. '\\FReporting\\saund'
    checkAndCreateFolder(sound)

    loadSettings()
    checkAndCreateFolder(sound_folder_path)
    audio = loadAudioStream(sound_file_path)
    audio2 = loadAudioStream(sound_file_path2)
     audio3 = loadAudioStream(sound_file_path3)
     audio4 = loadAudioStream(sound_file_path4)
     audio5 = loadAudioStream(sound_file_path5)


    if doesFileExist(logo.file) then
        logo.handle = imgui.CreateTextureFromFile(logo.file)
        if logo.handle then
            print("������� �������� �������.")
        else
            print("�� ������� ������� �������� ��������.")
        end
    else
        print("���� �������� �� ������: " .. logo.file)
    end
    
     if not doesFileExist(sound_file_path) then
         downloadUrlToFile("https://github.com/SaportBati/FReporting/raw/main/click.mp3", sound_file_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    print("�������� ���� click.mp3 ������� ��������")
                     audio = loadAudioStream(sound_file_path)
        end
        end)
    end

    if not doesFileExist(sound_file_path2) then
        downloadUrlToFile("https://github.com/SaportBati/FReporting/raw/refs/heads/main/click1.mp3", sound_file_path2, function(id, status)
            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                print("�������� ���� click1.mp3 ������� ��������")
                audio2 = loadAudioStream(sound_file_path2)
            end
        end)
    end
    
    if not doesFileExist(sound_file_path3) then
      downloadUrlToFile("https://github.com/SaportBati/FReporting/raw/refs/heads/main/click2.mp3", sound_file_path3, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            print("�������� ���� click2.mp3 ������� ��������")
            audio3 = loadAudioStream(sound_file_path3)
        end
       end)
    end
      if not doesFileExist(sound_file_path4) then
      downloadUrlToFile("https://github.com/SaportBati/FReporting/raw/refs/heads/main/click3.mp3", sound_file_path4, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            print("�������� ���� click3.mp3 ������� ��������")
            audio4 = loadAudioStream(sound_file_path4)
          end
        end)
    end
       if not doesFileExist(sound_file_path5) then
      downloadUrlToFile("https://github.com/SaportBati/FReporting/raw/refs/heads/main/click4.mp3", sound_file_path5, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            print("�������� ���� click4.mp3 ������� ��������")
            audio5 = loadAudioStream(sound_file_path5)
          end
        end)
    end
    

    sampAddChatMessage("[FReporting] {FFFFFF}==========================================", 0x00c2c2)
    sampAddChatMessage("[FReporting] {FFFFFF}����������� ������� {00c2c2}/frep {FFFFFF}��� �������� ����.", 0x00c2c2)
    sampAddChatMessage("[FReporting] {FFFFFF}������ ������� {00c2c2}" .. script_vers_text, 0x00c2c2)
    sampAddChatMessage("[FReporting] {FFFFFF}==========================================", 0x00c2c2)

    while true do
        wait(0)
          UpdateAlpha(main_window_state.v)
           imgui.Process = main_window_state.v or fAlpha > 0.00

        if spamEnabled and not anyWindowOpen and not tiplovli then
             if spamType.v == 1 then
                sampSendChat("/ot")
                  wait(speed)
              elseif spamType.v == 2 and isKeyDown(keys.VK_Q) then
                sampSendChat("/ot")
                 wait(speed)
                holdActive = true
                printStyledString('~g~Active', 100, 7)
              end
          end
        if holdActive and not isKeyDown(keys.VK_Q) then
              holdActive = false
        end
        

        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("[FReporting] {FFFFFF}������ ������� ��������!", 0x00c2c2)
                end
            end)
            break
        end
    end
end

function cmd_update(arg)
    sampShowDialog(1000, "��������������", "{FFF000}����� �����������3", "�������", "", 0)
end

function imgui.BeforeDrawFrame()
    if fontsize17 == nil then
        fontsize17 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 17.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fontsize19 == nil then
        fontsize19 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 19.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
    if fontsize22 == nil then
        fontsize22 = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 22.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

function imgui.OnDrawFrame()
      if main_window_state.v or fAlpha > 0.00 then
        local screenSize = imgui.GetIO().DisplaySize
        local windowSize = imgui.ImVec2(500, 500)
      local windowPos = imgui.ImVec2((screenSize.x - windowSize.x) / 2, (screenSize.y - windowSize.y) / 2 + windowYOffset)

        imgui.SetNextWindowPos(windowPos, imgui.Cond.Always)
        imgui.SetNextWindowSize(windowSize, imgui.Cond.FirstUseEver)
          imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.129, 0.129, 0.129, 1))
       imgui.Begin(u8'�� ����', main_window_state, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)
          
          -- ��������������� ����� ��� �������� ���� ������ ���� ���
          if  not windowOpened and main_window_state.v and soundEnabled.v then
            playSound()
            windowOpened = true
        end

        imgui.SetCursorPos(imgui.ImVec2(windowSize.x - 39, 3))

        local buttonSize = imgui.ImVec2(35, 23)
        imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.278, 0.278, 0.278, 1))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 1))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.2, 0.2, 1))
        if imgui.Button('x', buttonSize) then
            main_window_state.v = false
             stopSound()
        end
        imgui.PopStyleColor(3)
        imgui.PopStyleVar()

        if logo.handle then
            imgui.SetCursorPos(imgui.ImVec2(10, 10))
            imgui.Image(logo.handle, imgui.ImVec2(180, 50))
            print("������� ������������.")
        else
            print("������� �� ��������.")
        end

        imgui.SetCursorPos(imgui.ImVec2(10, 70))
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
        imgui.PushFont(fontsize17)
        imgui.Text(u8'������� ����� -')
        imgui.PopStyleColor()
        imgui.PopFont()

        imgui.SameLine()
        local toggleState = CustomToggleButton("##active", ActiveFluid, imgui.ImVec2(35, 20), fAlpha, soundEnabled.v)
        if toggleState then
           saveSettings()
        end

        imgui.NewLine()

       if ActiveFluid.v then
            imgui.SetCursorPos(imgui.ImVec2(10, 100))
            imgui.PushFont(fontsize17)
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
            imgui.Text(u8"��� ����� -")
            imgui.PopStyleColor()
            imgui.PopFont()
        
            imgui.SameLine()
        
            local buttonColor = tiplovli and imgui.ImVec4(0.5, 0.5, 0.5, 1) or imgui.ImVec4(0.278, 0.278, 0.278, 1)
            imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
            imgui.PushStyleColor(imgui.Col.Button, buttonColor)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.2, 0.2, 1))
            if imgui.Button(u8'1', imgui.ImVec2(40, 20)) then
                sampAddChatMessage("[FReporting] {FFFFFF}������ {00c2c2}������ {FFFFFF}��� �����", 0x00c2c2)
                tiplovli = false
                spamEnabled = false
                saveSettings()
            end
        
            if imgui.IsItemHovered() then
                if tiplovli then
                    imgui.SetTooltip(u8"������ ������ � ��� �������� /ot (������� �� ����� ������ �� �������)")
                else
                    imgui.SetTooltip(u8"��� �������")
                end
            end
        
            imgui.PopStyleColor(3)
            imgui.PopStyleVar()
        
            imgui.SameLine()
        
            buttonColor = tiplovli and imgui.ImVec4(0.278, 0.278, 0.278, 1) or imgui.ImVec4(0.5, 0.5, 0.5, 1)
            imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
            imgui.PushStyleColor(imgui.Col.Button, buttonColor)
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 1))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.2, 0.2, 0.2, 1))
            if imgui.Button(u8'2', imgui.ImVec2(40, 20)) then
                sampAddChatMessage("[FReporting] {FFFFFF}������ {00c2c2}������ {FFFFFF}��� �����", 0x00c2c2)
                tiplovli = true
                spamEnabled = false
                saveSettings()
            end
            
            if imgui.IsItemHovered() then
                if tiplovli then
                    imgui.SetTooltip(u8"��� �������")
                else
                   imgui.SetTooltip(u8"�������� �� ��������(�������� � ��������� �����������!)")
                end
            end
            
            imgui.PopStyleColor(3)
            imgui.PopStyleVar()

            imgui.SetCursorPos(imgui.ImVec2(10, 130))
            imgui.PushFont(fontsize17)
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
              imgui.Text(u8'��� ������������:')
            imgui.PopStyleColor()
            imgui.PopFont()
            
              
             local radioSize = imgui.ImVec2(20, 20)
           imgui.SetCursorPos(imgui.ImVec2(10, 160))
            imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
              if CustomRadioButton(u8"##radio1", spamType, 1, radioSize, fAlpha) then
              saveSettings()
            end
            imgui.SameLine()
           imgui.SetCursorPos(imgui.ImVec2(40, 160))
            imgui.Text(u8"Toggle")
           
             imgui.SameLine()
           imgui.SetCursorPos(imgui.ImVec2(100, 160))
           if CustomRadioButton(u8"##radio2", spamType, 2, radioSize, fAlpha) then
              saveSettings()
           end
            imgui.SameLine()
            imgui.SetCursorPos(imgui.ImVec2(130, 160))
            imgui.Text(u8"Hold")
            imgui.PopStyleVar()
             
            imgui.SetCursorPos(imgui.ImVec2(10, 190))
            imgui.PushFont(fontsize17)
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
            imgui.Text(u8'��������:')
            imgui.PopStyleColor()
            imgui.PopFont()
			imgui.SameLine()
         
           CustomSliderInt(u8"##speedSlider", sliderValue, 30, 200, fAlpha)
            speed = sliderValue.v
           saveSettings()
        end
         -- �������� �������������
         imgui.NewLine()
        imgui.SetCursorPos(imgui.ImVec2(10, ActiveFluid.v and 230 or 100))
         imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
         imgui.PushFont(fontsize17)
         imgui.Text(u8"�������� ������������� -")
         imgui.PopStyleColor()
         imgui.PopFont()

         imgui.SameLine()
        local soundToggleState = CustomToggleButton("##soundEnable", soundEnabled, imgui.ImVec2(35, 20), fAlpha, true)
        if soundToggleState then
            saveSettings()
        end
        if soundEnabled.v then
            imgui.SetCursorPos(imgui.ImVec2(10, ActiveFluid.v and 260 or 130))
            imgui.PushFont(fontsize17)
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
            imgui.Text(u8'��������� �����:')
            imgui.PopStyleColor()
            imgui.PopFont()
            imgui.SameLine()
            CustomSliderInt(u8"##soundVolumeSlider", soundVolume, 0, 100, fAlpha)
            saveSettings()
   
              imgui.SetCursorPos(imgui.ImVec2(10, ActiveFluid.v and 290 or 160))
           imgui.PushFont(fontsize17)
           imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
           imgui.Text(u8'��� �����:')
           imgui.PopStyleColor()
           imgui.PopFont()
           
             
            local radioSize = imgui.ImVec2(20, 20)
            
           imgui.SetCursorPos(imgui.ImVec2(10, ActiveFluid.v and 320 or 190))
           imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 3)
               if CustomRadioButton(u8"##radio1", soundType, 1, radioSize, fAlpha) then
                   if soundEnabled.v then
                       playSound()
                   end
                   saveSettings()
               end
            imgui.SameLine()
             imgui.SetCursorPos(imgui.ImVec2(40, ActiveFluid.v and 320 or 190))
              imgui.Text(u8"1")
          
               imgui.SameLine()
          imgui.SetCursorPos(imgui.ImVec2(70, ActiveFluid.v and 320 or 190))
          if CustomRadioButton(u8"##radio2", soundType, 2, radioSize, fAlpha) then
             if soundEnabled.v then
                 playSound()
               end
             saveSettings()
          end
           imgui.SameLine()
          imgui.SetCursorPos(imgui.ImVec2(100, ActiveFluid.v and 320 or 190))
           imgui.Text(u8"2")
           
             imgui.SameLine()
          imgui.SetCursorPos(imgui.ImVec2(130, ActiveFluid.v and 320 or 190))
          if CustomRadioButton(u8"##radio3", soundType, 3, radioSize, fAlpha) then
             if soundEnabled.v then
               playSound()
               end
           saveSettings()
            end
           imgui.SameLine()
          imgui.SetCursorPos(imgui.ImVec2(160, ActiveFluid.v and 320 or 190))
           imgui.Text(u8"3")
            
             imgui.SameLine()
           imgui.SetCursorPos(imgui.ImVec2(190, ActiveFluid.v and 320 or 190))
          if CustomRadioButton(u8"##radio4", soundType, 4, radioSize, fAlpha) then
            if soundEnabled.v then
                playSound()
             end
             saveSettings()
           end
           imgui.SameLine()
         imgui.SetCursorPos(imgui.ImVec2(220, ActiveFluid.v and 320 or 190))
           imgui.Text(u8"4")
              imgui.SameLine()
           imgui.SetCursorPos(imgui.ImVec2(250, ActiveFluid.v and 320 or 190))
          if CustomRadioButton(u8"##radio5", soundType, 5, radioSize, fAlpha) then
            if soundEnabled.v then
                  playSound()
              end
               saveSettings()
           end
           imgui.SameLine()
            imgui.SetCursorPos(imgui.ImVec2(280, ActiveFluid.v and 320 or 190))
             imgui.Text(u8"5")
            imgui.PopStyleVar()
         end
       
       imgui.NewLine()
       imgui.SetCursorPos(imgui.ImVec2(200, 10))
       
       imgui.PushFont(fontsize22)
       imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
       imgui.Text(u8"FReporting")
       imgui.PopStyleColor()
       imgui.PopFont()
   
       imgui.NewLine()
       imgui.SetCursorPos(imgui.ImVec2(10, 450))
       
       imgui.PushFont(fontsize17)
       imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
       imgui.Text(u8"�� ����� ��� ������������ ���������� �� ��� �:")
       imgui.PopStyleColor()
       imgui.PopFont()
   
       imgui.NewLine()
       imgui.SetCursorPos(imgui.ImVec2(10, 470))
       
       imgui.PushFont(fontsize17)
       imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1
       , 1))
               imgui.Text(u8"Discord - loceya | Telegram @NehtoOtto")
               imgui.PopStyleColor()
               imgui.PopFont()
       
               imgui.SetCursorPos(imgui.ImVec2(65, 35))
               imgui.PushFont(fontsize19)
               imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
               imgui.PopStyleColor()
               imgui.PopFont()
       
       
       
               imgui.End()
                 imgui.PopStyleColor()
           end
       end
       
       function onFrepCommand()
           main_window_state.v = not main_window_state.v
           windowOpened = false
       end
       
       function onSpiderCommand()
           sampAddChatMessage("[FReporting] {FFFFFF}�������� ��������{00c2c2} " .. speed, 0x00c2c2)
       end
       
       function onWindowMessage(msg, wparam, lparam)
            if msg == 0x100 or msg == 0x101 then
               if wparam == keys.VK_Q then
                   if not sampIsChatInputActive() and not sampIsDialogActive() and not imgui.IsAnyItemActive() then
                       if not qPressed then
                           if ActiveFluid.v and not tiplovli then
                               qPressed = true
                               if spamType.v == 1 then
                                   spamEnabled = not spamEnabled
                                    if spamEnabled then
                                         sampAddChatMessage("[FReporting] {FFFFFF}����� ������� ������� {7de07b}��������", 0x00c2c2)
                                           printStyledString('~g~ON', 1500, 7)
                                     else
                                          sampAddChatMessage("[FReporting] {FFFFFF}����� ������� ������� {e07b7b}���������", 0x00c2c2)
                                           printStyledString('~r~OFF', 1500, 7)
                                     end
                                 elseif spamType.v == 2 then
                                     spamEnabled = true
                                 end
                           end
                       end
                   end
               end
       
               if msg == 0x101 and wparam == keys.VK_Q then
                   qPressed = false
                      if spamType.v == 2 then
                         spamEnabled = false
                       end
               end
               
                if (wparam == keys.VK_ESCAPE and main_window_state.v) and not isPauseMenuActive() then
                   consumeWindowMessage(true, false)
                   main_window_state.v = false
                   stopSound()
                     windowOpened = false
               end
               if isAnyOtherWindowOpen() then
                   anyWindowOpen = true
                   if spamEnabled then
                       spamEnabled = false
                       sampAddChatMessage("{FF0000}���� ���������� ��-�� ��������� ����.", 0xFF0000)
                   end
               else
                   anyWindowOpen = false
               end
           end
       end
       
       function isAnyOtherWindowOpen()
           return false
       end
       
       sampRegisterChatCommand("frep", onFrepCommand)
       sampRegisterChatCommand("spider", onSpiderCommand)