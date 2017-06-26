local netstring = "EASY_CHAT_AFK"

if SERVER then
    util.AddNetworkString(netstring)
    
    local GetAFKTime = function(ply)
        if ply:IsAFK() and ply.afk_at_time then 
            return RealTime() - ply.afk_at_time
        else
            return 0
        end  
    end

    hook.Add("OnPlayerAFK","EasyChat",function(ent,afk)
        net.Start(netstring)
        net.WriteEntity(ent)
        net.WriteBool(afk)
        net.WriteFloat(ent:GetInfoNum("cl_afk_time",90) + GetAFKTime(ent))
        net.Broadcast()
        ent.afk_at_time = RealTime()
    end)

end

if CLIENT then
    net.Receive(netstring,function()
        local ply  = net.ReadEntity()
        local afk  = net.ReadBool()
        local time = net.ReadFloat()
        if afk then
            chat.AddText(Color(255,20,20),"⮞ ",Color(255,255,255),ply:GetName().." is now ",Color(255,20,20),"away")
        else
            chat.AddText(Color(20,255,20),"⮞ ",Color(255,255,255),ply:GetName().." is now ",Color(20,255,20),"back",Color(220,220,220)," (away for "..string.NiceTime(time)..")")
        end
    end)
end
