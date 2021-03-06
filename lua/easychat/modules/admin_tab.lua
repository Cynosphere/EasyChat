local EASYCHAT_ADMIN = "EASY_CHAT_MODULE_ADMIN"

if SERVER then
	util.AddNetworkString(EASYCHAT_ADMIN)

	net.Receive(EASYCHAT_ADMIN, function(_, ply)
		if not ply:IsAdmin() then return end
		local msg = net.ReadString()
		msg = msg:Trim()
		if msg == "" then return end

		local admins = {}
		for _,p in ipairs(player.GetAll()) do
			if p:IsAdmin() then
				table.insert(admins,p)
			end
		end

		net.Start(EASYCHAT_ADMIN)
		net.WriteEntity(ply)
		net.WriteString(msg)
		net.Send(admins)
	end)
end

if CLIENT then
	local PLY_COL = Color(255,127,127)
	local EC_HISTORY = GetConVar("easychat_history")

	local ADMIN_TAB = {
		NewMessages = 0,
		Init = function(self)
			local frame = self

			self.AdminList = self:Add("DListView")
			self.AdminList:SetWide(100)
			self.AdminList:Dock(LEFT)
			self.AdminList:AddColumn("Admins")

			self.TextEntry = self:Add("DTextEntry")
			self.TextEntry:SetTall(20)
			self.TextEntry:Dock(BOTTOM)
			self.TextEntry:SetHistoryEnabled(true)
			self.TextEntry.HistoryPos = 0
			self.TextEntry:SetUpdateOnType(true)

			if not EasyChat.UseDermaSkin then
				self.AdminList.Paint = function(self,w,h)
					surface.SetDrawColor(EasyChat.OutlayColor)
					surface.DrawRect(0, 0, w,h)
					surface.SetDrawColor(EasyChat.OutlayOutlineColor)
					surface.DrawOutlinedRect(0, 0, w,h)

					for i,ply in ipairs(player.GetAll()) do
						if ply:IsAdmin() then
							local tcol = team.GetColor(ply:Team())
							surface.SetFont("EasyChatFont")
							surface.SetTextPos(10,  20 * i)
							surface.SetTextColor(0,255,0,255)
							surface.DrawText("•")
							surface.SetTextPos(20,  20 * i)
							surface.SetTextColor(tcol.r,tcol.g,tcol.b,tcol.a)
							surface.DrawText(ply:Nick())
						end
					end
				end

				local header = self.AdminList.Columns[1].Header
				header:SetTextColor(Color(255,255,255))
				header.Paint = function(self,w,h)
					surface.SetDrawColor(EasyChat.OutlayColor)
					surface.DrawRect(0, 0, w,h)
					surface.SetDrawColor(EasyChat.OutlayOutlineColor)
					surface.DrawOutlinedRect(0, 0, w,h)
				end
			else
				local old_Paint = self.AdminList.Paint
				self.AdminList.Paint = function(self,w,h)
					old_Paint(self,w,h)
					for i,ply in ipairs(player.GetAll()) do
						if ply:IsAdmin() then
							local tcol = team.GetColor(ply:Team())
							surface.SetFont("EasyChatFont")
							surface.SetTextPos(10,  20 * i)
							surface.SetTextColor(0,255,0,255)
							surface.DrawText("•")
							surface.SetTextPos(20,  20 * i)
							surface.SetTextColor(tcol.r,tcol.g,tcol.b,tcol.a)
							surface.DrawText(ply:Nick())
						end
					end
				end
			end

			self.RichText = self:Add("RichText")
			self.RichText.HistoryName = "admin"
			if not EasyChat.UseDermaSkin then
				self.RichText:InsertColorChange(255,255,255,255)
			end
			self.RichText.PerformLayout = function(self)
				self:SetFontInternal("EasyChatFont")
				if not EasyChat.UseDermaSkin then
					self:SetFGColor(EasyChat.TextColor)
				end
			end
			self.RichText.ActionSignal = function(self,name,value)
				if name == "TextClicked" then
					EasyChat.OpenURL(value)
				end
			end
			self.RichText:Dock(FILL)

			local lastkey = KEY_ENTER
			self.TextEntry.OnKeyCodeTyped = function(self,code)
				EasyChat.SetupHistory(self,code)
				EasyChat.UseRegisteredShortcuts(self,lastkey,code)

				if code == KEY_ESCAPE then
					chat.Close()
					gui.HideGameUI()
				elseif code == KEY_ENTER or code == KEY_PAD_ENTER then
					self:SetText(string.Replace(self:GetText(),"╚​",""))
					if string.Trim(self:GetText()) ~= "" then
						frame:SendMessage(string.sub(self:GetText(),1,3000))
					end
				end

				lastkey = code
			end

			if EC_HISTORY:GetBool() then
				local history = EasyChat.ReadFromHistory("admin")
				if string.Trim(history) == "" then
					EasyChat.AddText(self, self.RichText, "Welcome to the admin chat!")
				else
					self.RichText:AppendText(history) -- so we do not log twice
					EasyChat.AddText(self, self.RichText, "\n^^^^^ Last Session History ^^^^^\n\n")
					self.RichText:GotoTextEnd()
				end
			else
				EasyChat.AddText(self, self.RichText, "Welcome to the admin chat!")
			end
		end,
		Notify = function(self,ply,message)
			if ply ~= LocalPlayer() then
				self.NewMessages = self.NewMessages + 1
				EasyChat.FlashTab("Admin")
			end
			_G.chat.AddText(Color(255,255,255),"[Admin Chat | ",Color(255,127,127),ply,Color(255,255,255),"] " .. message)
		end,
		SendMessage = function(self, msg)
			net.Start(EASYCHAT_ADMIN)
			net.WriteString(msg)
			net.SendToServer()
			self.TextEntry:SetText("")
		end,
	}

	vgui.Register("ECAdminTab", ADMIN_TAB, "DPanel")
	local admintab = vgui.Create("ECAdminTab")

	net.Receive(EASYCHAT_ADMIN,function()
		local sender = net.ReadEntity()
		local msg = net.ReadString()
		if not IsValid(sender) then return end

		EasyChat.AddText(admintab, admintab.RichText, team.GetColor(sender:Team()), sender,": " .. msg)
		if not EasyChat.IsOpened() then
			admintab:Notify(sender, msg)
		else
			local activetabname = EasyChat.GetActiveTab().Tab.Name
			if activetabname ~= "Admin" then
				admintab:Notify(sender, msg)
			end
		end
	end)

	hook.Add("ECTabChanged","EasyChatModuleDMTab",function(_,tab)
		if tab == "Admin" then
			admintab.NewMessages = 0
			admintab.RichText:GotoTextEnd()
			if not LocalPlayer():IsAdmin() then
				EasyChat.AddText(self, self.RichText, "You cannot see the content of this channel because you are not an admin")
			end
		end
	end)

	EasyChat.AddMode("Admin", function(text)
		admintab:SendMessage(text)
	end)
	EasyChat.AddTab("Admin", admintab)
	EasyChat.SetFocusForOn("Admin", admintab.TextEntry)
end

return "Admin Chat"