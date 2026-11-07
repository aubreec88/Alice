--!optimize 2

type ConnectionGroupType = {
	Name:string,
	Connections:{RBXScriptConnection?},
	
	MustDestroyManually:boolean?,
}

local RunService = game:GetService("RunService")

local Main = {
	Whine = RunService:IsStudio(),
	Groups = {},
}
Main.__index = Main

export type Groupful = typeof(setmetatable({} :: ConnectionGroupType, Main))

-- Ensures that the person always gets the class. @Y8
local function getSelf(Data:Groupful | string):Groupful
	const isString:boolean = (typeof(Data) == "string")
	
	if isString then
		return Main.GetConnectionGroup(Data)
	end
	
	return Data
end

-- Hehe @Y8
function Main.ToggleWhining(Toggle:boolean)
	Main.Whine = Toggle
end

--[[
	Creates a connection group that hosts connections.
	
	VALUES:
		Name:string
		Connections:{RBXScriptConnection?}
	
		MustDestroyManually:boolean?
		
	Giving the bool value "true" to the argument "MustDestroyManually" makes it so that the "DisconnectAll" function doesn't disconnect everything in the group when called.
	
	This function also has an assertion, regarding the group name, so it's recommended to be used inside of a pcall.
	
	@Y8
]]
function Main.CreateConnectionGroup(Values:ConnectionGroupType):Groupful
	assert(Values.Name, "No group name was given!")
	
	const ConnectionData:{RBXScriptConnection?} = (Values.Connections or {})
	const GroupName:string = (Values.Name :: string)
	const MustDestroyManually = Values.MustDestroyManually
	
	const groupData:ConnectionGroupType = {
		Name = GroupName,
		Connections = ConnectionData,
		MustDestroyManually = MustDestroyManually,
	} :: ConnectionGroupType
	
	Main.Groups[GroupName] = (setmetatable(groupData :: ConnectionGroupType, Main) :: Groupful)
	
	return Main.Groups[GroupName]
end

-- Gets the class of a connection group with a said name. If no class of a connection group exists with said name, creates one and returns that instead. @Y8
function Main.GetConnectionGroup(GroupName:string):Groupful
	local groupData:Groupful = (Main.Groups[GroupName] :: Groupful)
	
	if not groupData then		
		warn(string.format("A connection group with the name of %s didn't exist! Creating one and returning that instead!", GroupName))
		
		return Main.CreateConnectionGroup(GroupName)
	end
	
	return groupData
end

-- Inserts a connection into a connection group, duh. @Y8
function Main.AddConnection(self:Groupful | string, Connection:RBXScriptConnection)
	self = getSelf(self)
	
	table.insert(self.Connections, Connection)
end

--[[
	Disconnects the given connection and removes it from the "Connections" table of the connection groups class.
	Overall preferred way of disconnecting connections that are expected to be in said connection group.
	
	@Y8
]]
function Main.DisconnectConnection(self:Groupful | string, Connection:RBXScriptConnection)
	self = getSelf(self)
	
	local success, err = pcall(function()
		Connection:Disconnect()
		
		const connectionIndex:number = table.find(self.Connections, Connection)
		
		if not connectionIndex then
			if Main.Whine then
				error(string.format([[Couldn't find said connection inside of the "Connections" table for the connection group named %s!]], self.Name))
			end
			
			return
		end
		
		table.remove(self.Connections, connectionIndex)
	end)
	
	if not success then
		warn(err)
	end
end

-- Disconnects all of the connections inside of the connection group' class and cleans up the "Connections" table of the connection group' class afterwards. @Y8
function Main.DisconnectGroupConnections(self:Groupful | string)
	self = getSelf(self)
	
	for index, connection in self.Connections do
		local success, err = pcall(function()
			connection:Disconnect()
		end)
		
		if not success then
			warn(err)
		end
	end
	
	table.clear(self.Connections)
end

-- Cleans up all of the connections inside of the connection group' class and gets rid of its data. @Y8
function Main.DestroyGroup(self:Groupful | string)
	self = getSelf(self)
	
	self:DisconnectGroupConnections()
	
	Main.Groups[self.Name] = nil
end

--[[
	Cleans up all of the connections.
	Ignores connection groups that have the "MustDestroyManually" value set to the bool value "true" inside of its class data.
	
	@Y8
]]
function Main.DisconnectAll()
	for index, group in Main.Groups do
		task.spawn(function()
			if group.MustDestroyManually then
				return
			end

			group:DisconnectGroupConnections()
		end)
	end
end

return Main